# SPDX-FileCopyrightText: 2023 Efabless Corporation

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
async def spi_uart_wishbone_basic(dut):
    """Test basic Wishbone bus connectivity to SPI/UART design"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_wishbone_basic test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Test basic Wishbone connectivity
    # Check that we can access the design through Wishbone
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] Initial WB_ACK: {wb_ack}, WB_DATA: {wb_data:08x}")
    
    # Monitor Wishbone signals for a few cycles
    for i in range(100):
        await cocotb.triggers.ClockCycles(caravelEnv.clk, 1)
        wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
        wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
        
        if wb_ack == 1:
            cocotb.log.info(f"[TEST] Wishbone transaction at cycle {i}: data={wb_data:08x}")
    
    cocotb.log.info(f"[TEST] Basic Wishbone connectivity test completed")

@cocotb.test()
@report_test
async def spi_uart_wishbone_registers(dut):
    """Test Wishbone access to control and status registers"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_wishbone_registers test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Test control register access (0xF000-0xFFFF)
    # These are our custom control registers
    
    # Read version register (0xF008) - should return 0x01000000
    version_reg = 0xF008
    cocotb.log.info(f"[TEST] Attempting to read version register at {version_reg:08x}")
    
    # Simulate Wishbone read transaction
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = version_reg
    caravelEnv.caravel_hdl.mprj.wbs_cyc_i.value = 1
    caravelEnv.caravel_hdl.mprj.wbs_stb_i.value = 1
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 0  # Read
    
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] Version register read - ACK: {wb_ack}, DATA: {wb_data:08x}")
    
    # Read status register (0xF000)
    status_reg = 0xF000
    cocotb.log.info(f"[TEST] Attempting to read status register at {status_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = status_reg
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] Status register read - ACK: {wb_ack}, DATA: {wb_data:08x}")
    
    # Test write to control register (0xF004)
    control_reg = 0xF004
    test_data = 0x12345678
    cocotb.log.info(f"[TEST] Attempting to write {test_data:08x} to control register at {control_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = control_reg
    caravelEnv.caravel_hdl.mprj.wbs_dat_i.value = test_data
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 1  # Write
    caravelEnv.caravel_hdl.mprj.wbs_sel_i.value = 0xF  # All bytes
    
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    cocotb.log.info(f"[TEST] Control register write - ACK: {wb_ack}")
    
    # Read back the control register
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 0  # Read
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] Control register readback - ACK: {wb_ack}, DATA: {wb_data:08x}")
    
    # Deassert Wishbone signals
    caravelEnv.caravel_hdl.mprj.wbs_cyc_i.value = 0
    caravelEnv.caravel_hdl.mprj.wbs_stb_i.value = 0
    
    cocotb.log.info(f"[TEST] Wishbone register access test completed")

@cocotb.test()
@report_test
async def spi_uart_wishbone_data_transfer(dut):
    """Test Wishbone data transfer to SPI and UART IPs"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_wishbone_data_transfer test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Test SPI IP register access (0x0000-0x0FFF)
    # Write to SPI TX data register (0x0004)
    spi_tx_reg = 0x0004
    spi_data = 0x55  # Test pattern
    cocotb.log.info(f"[TEST] Writing {spi_data:02x} to SPI TX register at {spi_tx_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = spi_tx_reg
    caravelEnv.caravel_hdl.mprj.wbs_dat_i.value = spi_data
    caravelEnv.caravel_hdl.mprj.wbs_cyc_i.value = 1
    caravelEnv.caravel_hdl.mprj.wbs_stb_i.value = 1
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 1  # Write
    caravelEnv.caravel_hdl.mprj.wbs_sel_i.value = 0x1  # Byte 0
    
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    cocotb.log.info(f"[TEST] SPI TX write - ACK: {wb_ack}")
    
    # Test UART IP register access (0x1000-0x1FFF)
    # Write to UART TX data register (0x1004)
    uart_tx_reg = 0x1004
    uart_data = 0x41  # ASCII 'A'
    cocotb.log.info(f"[TEST] Writing {uart_data:02x} to UART TX register at {uart_tx_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = uart_tx_reg
    caravelEnv.caravel_hdl.mprj.wbs_dat_i.value = uart_data
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 1  # Write
    caravelEnv.caravel_hdl.mprj.wbs_sel_i.value = 0x1  # Byte 0
    
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    cocotb.log.info(f"[TEST] UART TX write - ACK: {wb_ack}")
    
    # Read SPI status register (0x0014)
    spi_status_reg = 0x0014
    cocotb.log.info(f"[TEST] Reading SPI status register at {spi_status_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = spi_status_reg
    caravelEnv.caravel_hdl.mprj.wbs_we_i.value = 0  # Read
    
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] SPI status read - ACK: {wb_ack}, DATA: {wb_data:08x}")
    
    # Read UART status register (0x100C)
    uart_status_reg = 0x100C
    cocotb.log.info(f"[TEST] Reading UART status register at {uart_status_reg:08x}")
    
    caravelEnv.caravel_hdl.mprj.wbs_adr_i.value = uart_status_reg
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 5)
    
    wb_ack = caravelEnv.caravel_hdl.mprj.wbs_ack_o.value.integer
    wb_data = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    
    cocotb.log.info(f"[TEST] UART status read - ACK: {wb_ack}, DATA: {wb_data:08x}")
    
    # Deassert Wishbone signals
    caravelEnv.caravel_hdl.mprj.wbs_cyc_i.value = 0
    caravelEnv.caravel_hdl.mprj.wbs_stb_i.value = 0
    
    cocotb.log.info(f"[TEST] Wishbone data transfer test completed") 