// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import "../src/interface/IConnector.sol";

import {Strategy} from "../src/curators/strategy.sol";
import {Oracle} from "../src/curators/oracle.sol";
import {Engine} from "../src/curators/engine.sol";

// connectors
import {MoonwellConnector} from "../src/protocols/lending/base/moonwell/main.sol";
import {MorphConnector} from "../src/protocols/lending/base/morpho/main.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Engine engine = new Engine();
        Strategy strategy = new Strategy(address(engine));

        Oracle oracle = new Oracle();

        new MoonwellConnector(
            "Moonwell Connector", IConnector.ConnectorType.LENDING, address(strategy), address(engine), address(oracle)
        );
        new MorphConnector(
            "Morpho Connector", IConnector.ConnectorType.LENDING, address(strategy), address(engine), address(oracle)
        );

        vm.stopBroadcast();
    }
}
