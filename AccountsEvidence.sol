// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/IAccountsEvidence.sol";

contract AccountsEvidence  is IAccountsEvidence, Ownable {

    mapping(address => address) private _accounts;

    function add(address fAddress, address tAddress) public onlyOwner{
        _accounts[fAddress] = tAddress;
    }


    function get(address fAddress) public view override returns(address){
        return _accounts[fAddress];
    }

    function remove(address fAddress) public onlyOwner {
        delete _accounts[fAddress];
    }

}