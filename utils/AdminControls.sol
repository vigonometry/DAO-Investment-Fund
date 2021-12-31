pragma solidity ^0.8.7;

contract AdminControls{
    address[] private admins;

    //initialise admin array by passing in the addresses of DAO founders
    constructor(address[] memory _admins){
        admins = _admins;
        admins.push(msg.sender);
    }

    //Function checks if the msg.sender is an admin
    function isAdmin() private view returns(bool){
        for (uint i = 0; i < admins.length; ++i){
            if (msg.sender == admins[i]){
                return true;
            }
        }
        return false;
    }


    modifier onlyAdmins(){
        require(isAdmin(), "Caller is not an admin");
        _;
    }

    function addAdmin(address _user) public onlyAdmins{
        admins.push(_user);
    }
}