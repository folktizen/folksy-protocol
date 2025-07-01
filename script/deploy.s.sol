// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/interface/IConnector.sol";

import { Strategy } from "../src/curators/strategy.sol";
import { Oracle } from "../src/curators/oracle.sol";
import { Engine } from "../src/curators/engine.sol";

// connectors
import { MoonwellConnector } from "../src/protocols/lending/base/moonwell/main.sol";
import { MorphConnector } from "../src/protocols/lending/base/morpho/main.sol";

contract Deploy is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    Engine engine = new Engine();
    Strategy strategy = new Strategy(address(engine));

    Oracle oracle = new Oracle();

    MoonwellConnector mwConnector = new MoonwellConnector(
      "Moonwell Connector", IConnector.ConnectorType.LENDING, address(strategy), address(engine), address(oracle)
    );
    MorphConnector morphoConnector = new MorphConnector(
      "Morpho Connector", IConnector.ConnectorType.LENDING, address(strategy), address(engine), address(oracle)
    );

    vm.stopBroadcast();

    // Prepare deployment info as JSON using vm.serializeAddress
    string memory json;
    json = vm.serializeAddress("deployment", "engineContract", address(engine));
    json = vm.serializeAddress("deployment", "strategyContract", address(strategy));
    json = vm.serializeAddress("deployment", "oracleContract", address(oracle));
    json = vm.serializeAddress("deployment", "moonwellConnector", address(mwConnector));
    json = vm.serializeAddress("deployment", "morphoConnector", address(morphoConnector));
    string memory output = vm.serializeString("deployment", "info", json);

    // Print deployment info to console
    console2.log("\n--- DEPLOYED FOLKSY ON BASE ---\n");
    console2.log(output);
  }
}
