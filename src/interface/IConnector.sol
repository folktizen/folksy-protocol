// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//////////////////////////////////////////////////////////////////
// @title   Folksy Protocol
// @notice  More at: https://folksy.space
// @version 1.1.0.CENDOL
// @author  Folktizen Labs
//////////////////////////////////////////////////////////////////
//
//    _______   ______    ___       __   ___   ________  ___  ___
//   /"     "| /    " \  |"  |     |/"| /  ") /"       )|"  \/"  |
//  (: ______)// ____  \ ||  |     (: |/   / (:   \___/  \   \  /
//   \/    | /  /    ) :)|:  |     |    __/   \___  \     \\  \/
//   // ___)(: (____/ //  \  |___  (// _  \    __/  \\    /   /
//  (:  (    \        /  ( \_|:  \ |: | \  \  /" \   :)  /   /
//   \__/     \"_____/    \_______)(__|  \__)(_______/  |___/
//
//////////////////////////////////////////////////////////////////

interface IConnector {
  /// @notice Core actions that a protocol can perform
  enum ActionType {
    SUPPLY, // Supply assets
    WITHDRAW, // Withdraw assets
    BORROW, // Borrow assets
    REPAY, // Repay debt
    STAKE, // Stake assets
    UNSTAKE, // Unstake assets
    SWAP, // Swap assets
    CLAIM // Claim rewards

  }

  enum ConnectorType {
    LENDING,
    DEX,
    YIELD
  }

  function getConnectorName() external view returns (bytes32);
  function getConnectorType() external view returns (ConnectorType);

  /// @notice Standard action execution interface
  function execute(
    ActionType actionType,
    address[] memory assetsIn,
    address assetOut,
    uint256 stepIndex,
    uint256 amountRatio,
    bytes32 strategyId,
    address userAddress,
    bytes calldata data
  )
    external
    payable
    returns (
      address protocol,
      address[] memory assets,
      uint256[] memory assetsAmount,
      address shareToken,
      uint256 shareAmount,
      address[] memory underlyingTokens,
      uint256[] memory underlyingAmounts
    );

  /// @notice Initially updates the user token balance
  function initialTokenBalanceUpdate(bytes32 strategyId, address userAddress, address token, uint256 amount) external;

  /// @notice Withdraw user asset
  function withdrawAsset(bytes32 _strategyId, address _user, address _token) external returns (bool);
}
