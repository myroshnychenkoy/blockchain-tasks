// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWhitelist {
    function addToWhitelist(address candidate) external;

    function removeFromWhitelist(address candidate) external;
}

abstract contract BaseToken is IWhitelist, ERC20 {
    mapping(address => bool) internal _whitelist;

    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _decimals = decimals;
    }

    function mintTo(address account, uint256 amount) external virtual {}

    function addToWhitelist(address candidate) external virtual override {}

    function removeFromWhitelist(address candidate) external virtual override {}

    function isMember(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {}
}


contract MyToken is BaseToken {
    address private _owner;

    constructor() BaseToken("My Token", "MT", 4) {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "MyToken: caller is not the owner");
        _;
    }

    function _checkZeroAddress(address addr) private pure {
        require(addr != address(0), "MyToken: zero address operation disallowed");
    }

    // Validator contract expects this function
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _checkZeroAddress(newOwner);
        _owner = newOwner;
    }

    function mintTo(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    function addToWhitelist(address candidate) external override onlyOwner {
        _checkZeroAddress(candidate);
        _whitelist[candidate] = true;
    }

    function removeFromWhitelist(address candidate) external override onlyOwner {
        _checkZeroAddress(candidate);
        _whitelist[candidate] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        bool isMint = _owner == msg.sender && from == address(0);
        bool isBurn = to == address(0);

        if (!isMint && !isBurn && to.code.length > 0 && !_whitelist[to]) {
            revert("MyToken: recipient contract is not whitelisted");
        }
    }
}
