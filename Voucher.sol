pragma solidity >=0.4.24 <0.6.0;

import "./WorkbenchBase.sol";
import "./VoucherSystem.sol";

contract Voucher is WorkbenchBase("VoucherSystem", "Voucher") {
    enum StateType { VoucherIssued, VoucherRedeemed}

    StateType public State;
    address public IssuingBank;
    address public Payee;
    int public Amount;
    string public Secret;
    int public Nonce;

    constructor(address _issuingBank, int _amount, string memory _secret, int _nonce) public {
        Bank bank = Bank(_issuingBank);
        //require(msg.sender == bank.BankerAddress, "msg.sender must be BankerAddress.");
        require(_amount > 0);
        require(bank.BankBalance() >= _amount);
        IssuingBank = _issuingBank;
        Amount = _amount;
        Secret = _secret;
        Nonce = _nonce;
        bank.UseNonce(_nonce);
        State = StateType.VoucherIssued;
        ContractCreated();
    }

    function Redeem(address _issuingBank, address _payee, string memory _secret, int _nonce) public {
        Bank bank = Bank(_issuingBank);
        require(Nonce == _nonce);
        require(bank.CheckNonce(_nonce));
        require(CompareSecret(_secret));
        bank.Transfer(_payee, Amount);
        State = StateType.VoucherRedeemed;
        Payee = _payee;
        ContractUpdated("Redeem");
    }

    function CheckValid() public view returns (bool) {
        return State == StateType.VoucherIssued;
    }

    function CompareSecret(string memory _secret) private view returns (bool) {
        return keccak256(abi.encode(Secret)) == keccak256(abi.encode(_secret));
    }

}
