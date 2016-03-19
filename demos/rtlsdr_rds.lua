local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local offset = -200e3

local top = radio.CompositeBlock()
local a0 = radio.RtlSdrSource(frequency + offset, 1102500, {autogain = true})
local a1 = radio.TunerBlock(offset, 200e6, 5)
local a2 = radio.FrequencyDiscriminatorBlock(5.0)
local a3 = radio.HilbertTransformBlock(257)
local f0 = radio.BandpassFilterBlock(165, {18e3, 20e3})
local b1 = radio.PLLBlock(1000.0, 19e3-100, 19e3+100, 3.0)
local c0 = radio.PLLBlock(1000.0, 19e3-100, 19e3+100, 1/16.0)
local c1 = radio.DelayBlock(35)
local c2 = radio.ComplexToRealBlock()
local a4 = radio.MultiplyConjugateBlock()
local a5 = radio.LowpassFilterBlock(256, 4e3)
local a6 = radio.RootRaisedCosineFilterBlock(101, 1, 1187.5)
local a7 = radio.BinaryPhaseCorrectorBlock(2000)
local e0 = radio.SamplerBlock()
local e1 = radio.ComplexToRealBlock()
local e2 = radio.SlicerBlock()
local e3 = radio.DifferentialDecoderBlock()
local e4 = radio.RDSFrameBlock()
local e5 = radio.RDSDecodeBlock()
local e6 = radio.JSONSink()

local p1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {yrange = {-120, -40}})
local p2 = radio.GnuplotSpectrumSink(2048, 'BPSK Spectrum', {yrange = {-130, -60}, xrange = {-8000, 8000}})
local p3 = radio.GnuplotXYPlotSink(1024, 'BPSK Constellation', {complex = true, yrange = {-0.03, 0.03}, xrange = {-0.03, 0.03}})

top:connect(a0, a1, a2, a3, f0)
top:connect(f0, b1)
top:connect(a3, 'out', a4, 'in1')
top:connect(b1, 'out', a4, 'in2')
top:connect(f0, c0, c1, c2)
top:connect(a4, a5, a6, a7)
top:connect(a7, 'out', e0, 'data')
top:connect(c2, 'out', e0, 'clock')
top:connect(e0, e1, e2, e3, e4, e5, e6)
top:connect(a2, p1)
top:connect(a6, p2)
top:connect(e0, p3)
top:run()
