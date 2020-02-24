pragma solidity ^0.6.0;

interface IERC20Module {
    function receiveERC20(
        address contractHere,
        address to,
        uint amount,
        bool isRaw) external returns (bytes memory);
    function sendERC20(address to, bytes calldata data) external returns (bool);
    function getReceiver(address to, bytes calldata data) external pure returns (address);
}