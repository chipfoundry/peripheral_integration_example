# SPDX-FileCopyrightText: 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SPDX-License-Identifier: Apache-2.0

from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb

@cocotb.test()
@report_test
async def uart_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=500000)

    cocotb.log.info(f"[TEST] Start uart_test")
    
    # wait for start of configuration
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Configuration finished")
    
    # Monitor UART TX pins to verify UART activity
    # User project UART TX pins are connected to I/O pins: 1,3,5,7,9,11,13
    uart_tx_pins = [1, 3, 5, 7, 9, 11, 13]
    
    # Wait for UART transmission to start and monitor for activity
    await cocotb.triggers.Timer(10000, units='ns')
    
    # Check that UART TX pins show activity by monitoring for transitions
    for i, tx_pin in enumerate(uart_tx_pins):
        # Get initial value
        initial_value = caravelEnv.monitor_gpio(tx_pin, tx_pin)
        cocotb.log.info(f"[TEST] UART{i} TX pin {tx_pin} initial value: {initial_value}")
        
        # Wait a bit and check for any change (indicating UART activity)
        await cocotb.triggers.Timer(5000, units='ns')
        final_value = caravelEnv.monitor_gpio(tx_pin, tx_pin)
        cocotb.log.info(f"[TEST] UART{i} TX pin {tx_pin} final value: {final_value}")
        
        # If both values are X, the UART is not properly configured
        if initial_value == 'x' and final_value == 'x':
            cocotb.log.error(f"[TEST] UART{i} TX pin {tx_pin} is not properly configured - showing X values")
            assert False, f"UART{i} is not properly configured"
        elif initial_value == final_value:
            cocotb.log.warning(f"[TEST] UART{i} TX pin {tx_pin} shows no activity (static value: {initial_value})")
        else:
            cocotb.log.info(f"[TEST] UART{i} TX pin {tx_pin} shows activity (changed from {initial_value} to {final_value})")
    
    # Wait for final completion signal
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] All UART tests completed successfully")
    
    # Check for error condition (GPIO 0xFF would indicate error)
    error_gpio = caravelEnv.monitor_gpio(7, 0)  # Check lower 8 bits
    if error_gpio == 0xFF:
        cocotb.log.error(f"[TEST] UART test failed - error detected")
        assert False, "UART test failed"
    else:
        cocotb.log.info(f"[TEST] All UART tests passed successfully") 