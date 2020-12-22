pragma solidity ^0.5.12;

contract AirDropper {

    address private owner;

    address payable [] senders;

    constructor(address _owner, address payable[] memory _senders) public {
        owner = _owner;
        senders = _senders;
    }

    function sendTRX() public {
        require(msg.sender == owner);
        for(uint256 i=0; i<senders.length; i++) {
            senders[i].transfer(80000000);
        }
    }
}
