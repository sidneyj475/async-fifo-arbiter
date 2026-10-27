
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_fifo_basic(dut):
    # Initialize inputs
    dut.winc.value = 0
    dut.rinc.value = 0
    dut.wdata.value = 0
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0

    # Start independent clocks
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 14, unit="ns").start())

    # Hold reset for several clock cycles
    await Timer(50, unit="ns")

    assert int(dut.rempty.value) == 1, "FIFO should be empty after reset"
    assert int(dut.wfull.value) == 0, "FIFO should not be full after reset"

    # Release reset
    dut.wrst_n.value = 1
    dut.rrst_n.value = 1

    await Timer(50, unit="ns")

    # Write one byte, keeping inputs stable across one write edge
    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.wdata.value = 0xA5
    dut.winc.value = 1

    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.winc.value = 0

    # Wait for write pointer synchronization into read domain
    for _ in range(10):
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        if int(dut.rempty.value) == 0:
            break
    else:
        assert False, "FIFO never became non-empty"

    # Asynchronous memory output should show oldest data
    assert int(dut.rdata.value) == 0xA5, "Incorrect FIFO data"

    # Read one byte
    dut.rinc.value = 1
    await RisingEdge(dut.rclk)
    await Timer(1, unit="ns")
    dut.rinc.value = 0

    # Check FIFO returns to empty
    assert int(dut.rempty.value) == 1, "FIFO should be empty after reading"
