// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

interface IAccountsEvidence {
    function get(address fAddress) external view returns(address);

}