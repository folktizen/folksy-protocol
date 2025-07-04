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

import "./interface/IStrategy.sol";
import { ERC4626, ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Engine is ERC4626 {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          EVENTS                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * @dev Emitted when a user joins a strategy
   * @param strategyId unique identifier for the strategy
   * @param depositor address of the user joining the strategy
   * @param tokenAddress depositing token address
   * @param amount amount used to join the strategy
   */
  event Join(bytes32 indexed strategyId, address indexed depositor, address[] tokenAddress, uint256[] amount);

  /**
   * @dev Emitted when a user joins a strategy
   * @param strategyId unique identifier for the strategy
   * @param user address of the user exiting the strategy
   */
  event Exit(bytes32 indexed strategyId, address indexed user);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERROR                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error InvalidActionType();

  constructor() ERC4626(IERC20(address(this))) ERC20("FOLKSY", "FOLK") { }

  function join(bytes32 _strategyId, address _strategyModule, uint256[] memory _amounts) public {
    // Fetch the strategy
    IFolksyStrategy.Strategy memory strategy = IFolksyStrategy(_strategyModule).getStrategy(_strategyId);

    // Validate strategy - not necessary single we validate the steps before strategy creation

    // Transfer initial deposit(s) from caller
    uint256 initialAssetsInLength = strategy.steps[0].assetsIn.length;

    for (uint256 i; i < initialAssetsInLength; i++) {
      address asset = strategy.steps[0].assetsIn[i];
      // approve `this` as spender in client first
      ERC4626(asset).transferFrom(msg.sender, address(this), _amounts[i]);
      // tranfer token to connector
      ERC4626(asset).transfer(_strategyModule, _amounts[i]);
      // set initial token balance
      IConnector(strategy.steps[0].connector).initialTokenBalanceUpdate(_strategyId, msg.sender, asset, _amounts[i]);
    }

    // Execute all steps atomically
    for (uint256 i; i < strategy.steps.length; i++) {
      // Fetch step
      IFolksyStrategy.Step memory step = strategy.steps[i];

      // Constrain the first step to certain actions
      if (
        i == 0
          && (
            (step.actionType == IConnector.ActionType.BORROW) || (step.actionType == IConnector.ActionType.UNSTAKE)
              || (step.actionType == IConnector.ActionType.WITHDRAW) || (step.actionType == IConnector.ActionType.REPAY)
          )
      ) revert();

      // Execute connector action
      try IConnector(step.connector).execute(
        step.actionType,
        step.assetsIn,
        step.assetOut,
        type(uint256).max,
        step.amountRatio,
        _strategyId,
        msg.sender,
        step.data
      ) returns (
        address protocol,
        address[] memory assets,
        uint256[] memory assetsAmount,
        address shareToken,
        uint256 shareAmount,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts
      ) {
        // Verify result
        // require(_verifyResult(shareAmount, step.assetOut, _strategyModule), "Invalid shareAmount");

        // update user info
        IFolksyStrategy(_strategyModule).updateUserStats(
          _strategyId,
          msg.sender,
          protocol,
          assets,
          assetsAmount,
          shareToken,
          shareAmount,
          underlyingTokens,
          underlyingAmounts,
          i
        );
      } catch Error(string memory reason) {
        revert(string(abi.encodePacked("Step ", i, " failed: ", reason)));
      }
    }

    // zero free for now
    uint256 _fee = 0;

    // update strategy stats
    IFolksyStrategy(_strategyModule).updateStrategyStats(
      _strategyId, strategy.steps[0].assetsIn, _amounts, msg.sender, _fee, 0
    );

    // update user's strategy array
    IFolksyStrategy(_strategyModule).updateUserStrategy(_strategyId, msg.sender, 0);

    // update the user's joined status
    IFolksyStrategy(_strategyModule).setJoinedStrategy(_strategyId, msg.sender, true);

    // Emits Join event
    emit Join(_strategyId, msg.sender, strategy.steps[0].assetsIn, _amounts);
  }

  function exit(bytes32 _strategyId, address _strategyModule) public {
    // check and burn user's liquid share token (also prevent re-enterancy)

    // Fetch the strategy
    IFolksyStrategy.Step[] memory steps = IFolksyStrategy(_strategyModule).getStrategy(_strategyId).steps;

    // Execute all steps in reverse atomically
    for (uint256 i = steps.length; i > 0; i--) {
      // Fetch step
      IFolksyStrategy.Step memory step = steps[i - 1];

      address[] memory assetsIn;
      address assetOut;
      // Flip action type (unsure if repay and withdraw would be part of strategy steps)
      IConnector.ActionType actionType;
      if (step.actionType == IConnector.ActionType.SUPPLY) {
        actionType = IConnector.ActionType.WITHDRAW;

        // asset in
        assetsIn = new address[](1);
        assetsIn[0] = step.assetOut;

        // asset out
        assetOut = step.assetsIn[0];
      } else if (step.actionType == IConnector.ActionType.BORROW) {
        actionType = IConnector.ActionType.REPAY;

        // asset in
        assetsIn = new address[](3);
        assetsIn[0] = step.assetOut;
        assetsIn[1] = step.assetsIn[1];
        assetsIn[2] = step.assetsIn[2];
      } else {
        revert InvalidActionType();
      }

      // Execute connector action
      try IConnector(step.connector).execute(
        actionType, assetsIn, assetOut, i - 1, 0, _strategyId, msg.sender, step.data
      ) returns (
        address,
        address[] memory,
        uint256[] memory,
        address assetOut,
        uint256 amountOut,
        address[] memory,
        uint256[] memory
      ) {
        // Some checks here

        // Transfer token to user
        if (i == 1) {
          // todo: get all the assetout then send
          for (uint256 j; j < step.assetsIn.length; j++) {
            IConnector(step.connector).withdrawAsset(_strategyId, msg.sender, step.assetsIn[j]);
          }
        }
      } catch Error(string memory reason) {
        revert(string(abi.encodePacked("Step ", i - 1, " failed: ", reason)));
      }
    }

    IFolksyStrategy.AssetBalance memory userAssetBalance =
      IFolksyStrategy(_strategyModule).getUserAssetBalance(_strategyId, msg.sender, steps[0].assetsIn, 0);

    // zero free for now
    uint256 _fee = 0;

    // update strategy stats
    IFolksyStrategy(_strategyModule).updateStrategyStats(
      _strategyId, steps[0].assetsIn, userAssetBalance.amounts, msg.sender, _fee, 1
    );

    // update user strategy stats
    IFolksyStrategy(_strategyModule).updateUserStrategy(_strategyId, msg.sender, 1);

    // update the user's joined status
    IFolksyStrategy(_strategyModule).setJoinedStrategy(_strategyId, msg.sender, false);

    // Emits Exit event
    emit Exit(_strategyId, msg.sender);
  }

  function _verifyResult(uint256 _shareAmount, address _assetOut, address _strategyModule) internal view returns (bool) {
    return ERC4626(_assetOut).balanceOf(_strategyModule) == _shareAmount;
  }
}
