// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Pausable is Context {
    /**
     *  Emitted when the freeze is triggered by `account`.
     */
    event Frozen(address account);

    /**
     *  Emitted when the freeze is lifted by `account`.
     */
    event Unfrozen(address account);

    bool private _frozen;

    /**
     *  Initializes the contract in unfrozen state.
     */
    constructor() {
        _frozen = false;
    }

    /**
     *  Returns true if the contract is frozen, and false otherwise.
     */
    function frozen() public view returns (bool) {
        return _frozen;
    }

    /**
     *  Modifier to make a function callable only when the contract is not frozen.
     *
     * Requirements:
     *
     * - The contract must not be frozen.
     */
    modifier whenNotFrozen() {
        require(!frozen(), "Freezable: frozen");
        _;
    }

    /**
     *  Modifier to make a function callable only when the contract is frozen.
     *
     * Requirements:
     *
     * - The contract must be frozen.
     */
    modifier whenFrozen() {
        require(frozen(), "Freezable: frozen");
        _;
    }

    /**
     *  Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be frozen.
     */
    function _freeze() internal whenNotFrozen {
        _frozen = true;
        emit Frozen(_msgSender());
    }

    /**
     *  Returns to normal state.
     *
     * Requirements:
     *
     * - Can only be called by the current owner.
     * - The contract must be frozen.
     */
    function _unfreeze() internal whenFrozen {
        _frozen = false;
        emit Unfrozen(_msgSender());
    }
}

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!frozen(), "ERC1155Pausable: token transfer while paused");
    }
}

contract GDFCARD is
    Context,
    AccessControlEnumerable,
    ERC1155,
    ERC1155Burnable,
    ERC1155Pausable
{
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Base Metadata URI
    string public baseMetadataURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseMetadataURI
    ) ERC1155(baseMetadataURI) {
        name = _name;
        symbol = _symbol;
        baseMetadataURI = _baseMetadataURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        mint(msg.sender, 101, 1000, "SLIVER CARD");
        mint(msg.sender, 201, 2000, "GOD CARD");
        mint(msg.sender, 301, 3000, "PLATIUM CARD");
        mint(msg.sender, 501, 5000, "DIMOND CARD");
    }

    /**
     * Generate URI by id.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseMetadataURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "GDFCARD: must have minter role to setBaseMetadataURI"
        );
        baseMetadataURI = _newBaseMetadataURI;
        _setURI(baseMetadataURI);
    }

    /**
     * Creates `amount` new tokens for `to`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "GDFCARD: must have minter role to mint"
        );

        _mint(to, id, amount, data);
    }

    /**
     * xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "GDFCARD: must have minter role to mint"
        );

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * Pauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "DoragonLandCards: must have pauser role to pause"
        );
        _freeze();
    }

    /**
     * Unpauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "GDFCARD: must have pauser role to unpause"
        );
        _unfreeze();
    }

    /**
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
