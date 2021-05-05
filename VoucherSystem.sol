pragma solidity >=0.4.24 <0.6.0;

import "./WorkbenchBase.sol";
import "./Voucher.sol";

contract Bank is WorkbenchBase("VoucherSystem", "Bank") {
    enum StateType { BankFunded, VouchersInCirculation}

    StateType public State;
    address public BankAddress;
    address public BankerAddress;
    int public MoneySupply;
    int public BankBalance;
    int public AmountInWallets;
    int public AmountInVouchers;
    int public NumVouchers;

    struct Wallet {
        int Balance;
    }

    mapping (address => Wallet) public Wallets;
    mapping (int => Voucher) public Vouchers;
    mapping (address => mapping(int => bool)) public Nonces;

    constructor(int _initialSupply) public {
        BankAddress = address(this);
        BankerAddress = msg.sender;
        MoneySupply += _initialSupply;
        BankBalance += _initialSupply;
        State = StateType.BankFunded;
        ContractCreated();
    }

    function Supply(int _amount) public {
        require(msg.sender == BankerAddress);
        require(_amount > 0);
        MoneySupply += _amount;
        BankBalance += _amount;
        ContractUpdated("Supply");
    }

    function Burn(int _amount) public {
        require(msg.sender == BankerAddress);
        require(_amount > 0);
        require(_amount <= BankBalance);
        BankBalance -= _amount;
        MoneySupply -= _amount;
        ContractUpdated("Burn");
    }

    function Transfer(address _payee, int _amount) public {
        require(_amount > 0);
        if (msg.sender != BankerAddress) {
            require(Wallets[msg.sender].Balance >= _amount);
        } else {
            require(BankBalance >= _amount);
        }
        if (_payee == BankerAddress) {
            BankBalance += _amount;
        } else {
            Wallets[_payee].Balance += _amount;
        }
        if (msg.sender == BankerAddress) {
            BankBalance -= _amount;
            AmountInWallets += _amount;
        } else {
            Wallets[msg.sender].Balance -= _amount;
        }
        ContractUpdated("Transfer");
    }

    function UseNonce(int _nonce) public returns (bool) {
        Nonces[msg.sender][_nonce] = true;
        return Nonces[msg.sender][_nonce];
    }

    function CheckNonce(int _nonce) public view returns (bool) {
        return Nonces[msg.sender][_nonce];
    }

    function IssueVoucher(int _amount, string memory _secret, int _nonce) public {
        require(msg.sender == BankerAddress);
        require(_amount > 0);
        require(_amount <= BankBalance);
        require(!Nonces[msg.sender][_nonce]);
        NumVouchers = NumVouchers++;
        Vouchers[NumVouchers] = new Voucher(address(this), _amount, _secret, _nonce);
        Wallets[address(Vouchers[NumVouchers])].Balance += _amount;
        BankBalance -= _amount;
        AmountInVouchers += _amount;
        State = StateType.VouchersInCirculation;
        ContractUpdated("IssueVoucher");
    }

    function RedeemVoucher(int _ID, address _payee, string memory _secret, int _nonce) public {
        Voucher v = Voucher(Vouchers[_ID]);
        require(v.CheckValid());
        v.Redeem(address(this), _payee, _secret, _nonce);
        ContractUpdated("RedeemVoucher");
    }

}
