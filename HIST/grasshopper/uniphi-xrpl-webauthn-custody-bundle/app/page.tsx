import ClientPanel from '../components/ClientPanel';

export default function Page() {
  return (
    <>
      <h1>Uniphi XRPL Custody — Passkeys + Immutable Registry + EVM Contract</h1>
      <p>
        Two layers, one stage:
        <br/>• <b>XRPL (classic ledger)</b>: immutable proofs via on-ledger transactions (Memo registry).
        <br/>• <b>XRPL EVM sidechain</b>: optional Solidity registry contract deployment.
      </p>
      <ClientPanel />
      <div className="hr" />
      <p>
        <small>
          Keep <code>.env</code> local. Start on testnets.
        </small>
      </p>
    </>
  );
}
