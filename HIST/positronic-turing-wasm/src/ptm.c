// Positronic Differentiable Turing Machine core
// Build: clang --target=wasm32 -O3 -nostdlib -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined -o ptm.wasm ptm.c

#define N 128
#define STATES 8
#define SYMBOLS 6
#define PI 3.14159265358979323846f

static float tape[N];          // differentiable symbol field [-1,1]
static float charge[N];        // positronic charge / confidence [0,1]
static float glow[N];          // visual energy
static float head[N];          // soft attention over tape
static float newHead[N];
static float state[STATES];    // soft finite-state vector
static float newState[STATES];
static float logits[STATES * SYMBOLS];
static unsigned int rng = 0xC0FFEEu;
static int initialized = 0;
static float global_error = 0.0f;
static float global_phase = 0.0f;

static float absf(float x){ return x < 0.0f ? -x : x; }
static float clamp(float x, float a, float b){ return x < a ? a : (x > b ? b : x); }
static float fract(float x){ int i=(int)x; return x-(float)i; }
static float fast_sin(float x){
  while(x > PI) x -= 2.0f*PI;
  while(x < -PI) x += 2.0f*PI;
  float x2 = x*x;
  return x * (1.0f - x2/6.0f + (x2*x2)/120.0f - (x2*x2*x2)/5040.0f);
}
static float fast_cos(float x){ return fast_sin(x + PI*0.5f); }
static float sigmoid(float x){ return 0.5f + x / (2.0f * (1.0f + absf(x))); }
static float rnd(){
  rng = 1664525u * rng + 1013904223u;
  return ((rng >> 8) & 0xFFFFFFu) / 16777216.0f;
}
static void normalize(float *v, int n){
  float s=0.000001f;
  for(int i=0;i<n;i++) s += v[i];
  for(int i=0;i<n;i++) v[i] /= s;
}

__attribute__((export_name("init")))
void init(unsigned int seed){
  rng = seed ? seed : 0xC0FFEEu;
  for(int i=0;i<N;i++){
    float x=(float)i/(float)N;
    tape[i] = 0.32f*fast_sin(2.0f*PI*x*3.0f) + 0.18f*fast_sin(2.0f*PI*x*13.0f + 1.7f);
    charge[i] = 0.45f + 0.15f * fast_sin(2.0f*PI*x*5.0f);
    glow[i] = 0.0f;
    float d = (float)i - 0.5f*(float)N;
    head[i] = 1.0f / (1.0f + d*d*0.15f);
  }
  normalize(head, N);
  for(int s=0;s<STATES;s++) state[s] = (s==0) ? 1.0f : 0.0f;
  for(int i=0;i<STATES*SYMBOLS;i++) logits[i] = (rnd()*2.0f-1.0f)*0.35f;
  initialized = 1;
}

__attribute__((export_name("step")))
float step(float dt, float audio, float bloom, float rings, float magneto, float beads, float learning){
  if(!initialized) init(0xC0FFEEu);
  global_phase += dt * (0.25f + 0.8f*rings);

  // differentiable read: soft attention over tape
  float read=0.0f, confidence=0.0f, pos=0.0f;
  for(int i=0;i<N;i++){
    read += head[i] * tape[i];
    confidence += head[i] * charge[i];
    pos += head[i] * (float)i;
  }

  // target oscillator acts like a teacher signal / differentiable oracle
  float target = 0.6f*fast_sin(global_phase + audio*2.0f) + 0.25f*fast_sin(global_phase*3.0f + beads*6.0f);
  global_error = target - read;

  // state transition: softmax-ish normalized positive activations
  for(int s=0;s<STATES;s++){
    float recurrent = 0.0f;
    for(int k=0;k<STATES;k++){
      float w = fast_sin((float)(s+1)*(float)(k+2)*0.77f + magneto*2.0f);
      recurrent += state[k] * w;
    }
    float z = recurrent + read*(0.8f-0.08f*s) + confidence*0.35f + audio*0.2f;
    newState[s] = 0.01f + sigmoid(z);
  }
  normalize(newState, STATES);
  for(int s=0;s<STATES;s++) state[s] = newState[s];

  // write field: a differentiable program emits symbols from soft state + logits
  float write=0.0f;
  for(int s=0;s<STATES;s++){
    for(int y=0;y<SYMBOLS;y++){
      float symbol = -1.0f + 2.0f*((float)y/(float)(SYMBOLS-1));
      float p = sigmoid(logits[s*SYMBOLS+y] + read*symbol + state[s]);
      write += state[s] * p * symbol;
      logits[s*SYMBOLS+y] += learning * global_error * state[s] * symbol * 0.0025f;
    }
  }
  write = clamp(write, -1.0f, 1.0f);

  // soft write to tape and update charge
  for(int i=0;i<N;i++){
    float h = head[i];
    float local = fast_sin(global_phase + (float)i*0.31f + audio*4.0f);
    tape[i] = clamp(tape[i]*(1.0f - h*0.22f*bloom) + h*(write + global_error*0.35f + local*0.05f), -1.0f, 1.0f);
    charge[i] = clamp(charge[i]*0.985f + h*(0.25f + confidence*0.5f) + absf(global_error)*0.01f, 0.0f, 1.0f);
    glow[i] = glow[i]*0.94f + h*(0.5f + absf(write))*bloom + absf(local)*0.01f;
  }

  // differentiable head motion: no hard left/right; attention shifts by expectation
  float velocity = magneto*(read + global_error) * 2.5f + audio*1.2f + fast_sin(global_phase*0.5f)*rings;
  for(int i=0;i<N;i++){
    float src = (float)i - velocity;
    int a = (int)src;
    float f = src - (float)a;
    int i0 = (a % N + N) % N;
    int i1 = ((a+1) % N + N) % N;
    float smear = 0.003f + beads*0.015f;
    newHead[i] = head[i0]*(1.0f-f) + head[i1]*f + smear;
  }

  // ring/bloom focus gate
  for(int i=0;i<N;i++){
    float d = absf((float)i - pos);
    float ring = 1.0f/(1.0f + d*d*(0.012f + rings*0.04f));
    newHead[i] = newHead[i]*(1.0f-bloom*0.05f) + ring*bloom*0.05f;
  }
  normalize(newHead, N);
  for(int i=0;i<N;i++) head[i] = newHead[i];

  return global_error;
}

__attribute__((export_name("cell"))) float cell(int i){ return tape[(i%N+N)%N]; }
__attribute__((export_name("charge"))) float cell_charge(int i){ return charge[(i%N+N)%N]; }
__attribute__((export_name("attention"))) float attention(int i){ return head[(i%N+N)%N]; }
__attribute__((export_name("energy"))) float energy(int i){ return glow[(i%N+N)%N]; }
__attribute__((export_name("state"))) float get_state(int i){ return state[(i%STATES+STATES)%STATES]; }
__attribute__((export_name("error"))) float get_error(){ return global_error; }
__attribute__((export_name("size"))) int size(){ return N; }
__attribute__((export_name("states"))) int states(){ return STATES; }
