import './style.css';
export const metadata = { title: 'Arduino IoT Lab', description: 'Live sensor flow canvas' };
export default function RootLayout({children}:{children:React.ReactNode}) {
  return <html><body>{children}</body></html>;
}
