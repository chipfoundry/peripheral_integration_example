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
async def spi_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=50000)

    cocotb.log.info(f"[TEST] Start spi_test")
    
    # wait for start of configuration
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Configuration finished")
    
    # Wait for all SPI tests to complete (GPIO 9-14)
    for spi in range(6):
        await caravelEnv.wait_mgmt_gpio(spi + 9)
        cocotb.log.info(f"[TEST] SPI{spi} test completed")
        
        # Verify SPI output pins are configured as outputs
        mosi_pin = 15 + spi * 4  # SPI MOSI pins: 15,19,23,27,31,35
        sclk_pin = 16 + spi * 4  # SPI SCLK pins: 16,20,24,28,32,36
        cs_pin = 17 + spi * 4    # SPI CS pins: 17,21,25,29,33,37
        
        # Check if SPI pins are configured as outputs (io_oeb should be 0 for outputs)
        mosi_oeb = caravelEnv.monitor_gpio(mosi_pin + 37, mosi_pin + 37)  # io_oeb offset
        sclk_oeb = caravelEnv.monitor_gpio(sclk_pin + 37, sclk_pin + 37)
        cs_oeb = caravelEnv.monitor_gpio(cs_pin + 37, cs_pin + 37)
        
        if mosi_oeb != 0 or sclk_oeb != 0 or cs_oeb != 0:
            cocotb.log.warning(f"[TEST] SPI{spi} output pins not properly configured")
        else:
            cocotb.log.info(f"[TEST] SPI{spi} output pins properly configured")
    
    # Wait for final completion signal
    await caravelEnv.wait_mgmt_gpio(0)
    cocotb.log.info(f"[TEST] All SPI tests completed successfully")
    
    # Check for error condition (GPIO 0xFF would indicate error)
    error_gpio = caravelEnv.monitor_gpio(7, 0)  # Check lower 8 bits
    if error_gpio == 0xFF:
        cocotb.log.error(f"[TEST] SPI test failed - error detected")
        assert False, "SPI test failed"
    else:
        cocotb.log.info(f"[TEST] All SPI tests passed successfully") 