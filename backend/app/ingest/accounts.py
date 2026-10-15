"""Xác định giao dịch thuộc tài khoản nào. TK lạ không bao giờ tự động được tính vào tổng."""

from __future__ import annotations

from sqlmodel import Session, select

from app.ingest.schema import NormalizedTx
from app.models import Account


def _bank_ok(acc: Account, bank: str | None) -> bool:
    return bank is None or acc.bank in (bank, "OTHER")


def find_account(session: Session, bank: str | None, number: str | None, last4: str | None) -> Account | None:
    accounts = list(session.exec(select(Account).where(Account.bank != "CASH")).all())
    if number:
        exact = [a for a in accounts if a.account_number == number and _bank_ok(a, bank)]
        if len(exact) == 1:
            return exact[0]
        if not exact:
            exact = [a for a in accounts if a.account_number == number]
            if len(exact) == 1:
                return exact[0]
        # TK mới chỉ biết 4 số cuối -> bổ sung số đầy đủ
        partial = [a for a in accounts if not a.account_number and a.last4 == number[-4:] and _bank_ok(a, bank)]
        if len(partial) == 1:
            partial[0].account_number = number
            session.add(partial[0])
            return partial[0]
        return None
    if last4:
        cands = [a for a in accounts if a.last4 == last4 and _bank_ok(a, bank)]
        return cands[0] if len(cands) == 1 else None
    if bank:
        cands = [a for a in accounts if a.bank == bank]
        return cands[0] if len(cands) == 1 else None
    return None


def resolve_account(session: Session, ntx: NormalizedTx) -> tuple[Account, bool]:
    """Trả về (account, created). TK mới: include_in_total=False, confirmed=False."""
    acc = find_account(session, ntx.bank, ntx.account_number, ntx.account_last4)
    if acc is not None:
        if ntx.bank and acc.bank == "OTHER":
            acc.bank = ntx.bank
            session.add(acc)
        return acc, False
    bank = ntx.bank or "OTHER"
    last4 = ntx.account_last4
    name = f"{bank} …{last4}" if last4 else f"{bank} (chưa rõ số TK)"
    acc = Account(bank=bank, account_number=ntx.account_number, last4=last4, name=name,
                  include_in_total=False, confirmed=False)
    session.add(acc)
    session.flush()
    return acc, True


def cash_account(session: Session) -> Account:
    """TK ảo cho giao dịch nhập tay không gắn TK ngân hàng."""
    acc = session.exec(select(Account).where(Account.bank == "CASH")).first()
    if acc is None:
        acc = Account(bank="CASH", name="Tiền mặt / nhập tay", include_in_total=False, confirmed=True)
        session.add(acc)
        session.flush()
    return acc
