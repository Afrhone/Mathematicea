import './globals.css';

export const metadata = {
  title: 'Uniphi XRPL Custody (WebAuthn)',
  description: 'Passkey-gated custodial XRPL wallet + XRPL EVM registry contract.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <div className="container">{children}</div>
      </body>
    </html>
  );
}
