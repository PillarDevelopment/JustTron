pragma solidity ^0.5.12;

contract WGRM {
    string public name     = "Wrapped PROGRAM";
    string public symbol   = "WGRM";
    uint8  public decimals = 6;
    trcToken public tokenID;  // 1003500

    address public custodian;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor(uint256 _tokenID) public {
        tokenID = trcToken(_tokenID);
        custodian = msg.sender;
    }

    function() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.tokenvalue;
        emit Deposit(msg.sender, msg.tokenvalue);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transferToken(wad, tokenID);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).tokenBalance(tokenID);
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function getTRX() public {
        require(msg.sender == custodian);
        custodian.transfer(address(this).balance);
    }
}
