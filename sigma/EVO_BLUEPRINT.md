THE LAST HARNESS You'LL Ever BUILD
Haebin Seong
Sylph.AI
Li Yin
Sylph.AI
Haoran Zhang
Sylph.AI
Zhan Shi Sylph.AI
ABSTRACT
Al agents are increasingly deployed on complex, domain-specific workflows— navigating enterprise web applications that require dozens of clicks and form fills, orchestrating multi-step research pipelines that span search, extraction, and syn-thesis, automating code review across unfamiliar repositories, and handling customer escalations that demand nuanced domain knowledge. Each new task domain requires painstaking, expert-driven harness engineering: designing the prompts, tools, orchestration logic, and evaluation criteria that make a foundation model effective. We present a two-level framework that automates this process.
At the first level, the Harness Evolution Loop optimizes a worker agent's harness H for a single task: a Worker Agent Wa executes the task, an Evaluator Agent V adversarially diagnoses failures and scores performance, and an Evolution Agent E modifies the harness based on the full history of prior attempts.
At the second level, the Meta-Evolution Loop optimizes the evolution blueprint A = (Wz, HL(°), V, E) itself across diverse tasks, learning a blueprint 1 (best) that enables rapid harness convergence on any new task-so that adapting an agent to a novel domain requires no human harness engineering at all. We formalize the correspondence to meta-learning and present both algorithms. The framework shifts manual harness engineering into automated harness engi-neering, and takes one step further—automating the design of the automation itself.