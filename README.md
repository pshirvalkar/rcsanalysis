Deserialization of RC+S Time Domain and Accelerometry Data
==

Overview: 
-------------

The RC+S streams data in packet form. Because the streaming backend employs a UDP-like protocol (where there is no capacity for packet recovery), it becomes critical to account for packet loss during streaming and data post-processing. Failing to account for packet loss will adversely affect computation of PSDs and other event related measures.

For most data science applications, it is useful to format data in a "tidy" matrix in which each row represents an instance of a time domain measurement and each column represents the set of features associated with that particular measurement (i.e. the metadata). Our code performs the operation of efficiently transforming raw data from the RC+S (saved in the form a JSON file) into a CSV file (albeit at the expense of increased storage utilization).

Below is a visual summary of what raw saved data looks like (in JSON form) vs. the derived data from our code:

![converting .json to .csv](figures/conversion.jpg)

Implementation Overview: 
-------------

* `Matlab`
	* Parses RC+S time domain data (in the form of a `RawDataTD.json` file) into a CSV output with samples along rows and channels in columns.
	* Creation of a CSV file is optional thus allowing for in-memory manipulation of the data without the overhead time associated with data saving it to disk.

* `Python`
	* Parses both RC+S time domain and accelerometry data (in the form of a `RawDataTD.json` or a `RawDataAccel.json` file) into a  CSV output with samples along rows and channels in columns.
	* Command-line arguments are available for control of timestamp processing (timestamps may be left in seconds since March 1st, 2000 or converted into a human-readable datetime format)
	* Packet deserializer can be invoked from the command-line via the `python` interpretor and run as a standalone program, or the deserializer can be imported as a module into a python program of your creation giving you access to the processing functions contained therein.

Samples of raw RC+S time domain data (in JSON format) with the processed "tidy" output created from it are available in the `sample_data` folder of this repo.

Schematic Example of RC+S Packet Structure: 
-------------

![RC+S schematics](figures/packet-loss.jpg)

#### RC+S Packet Metadata

The following packet headers are found in a `RawDataTD.json` file:

`dataTypeSequence` - 8bit Packet number counter, rolls over.

`systemTick` - 16bit INS clock-driven tick counter, rolls over, LSB is 100microseconds (high accuracy and resolution).

`TdSampleRates` - Hexadecimal value corresponding to sample rate used for a given recording: 0x00 is 250Hz, 0x01 is 500Hz, 0x02 is 1000Hz, and 0xF0 is disabled.   

`timestamp`  Timezone-naive INS wall clock time, does not roll over, LSB is seconds (high accuracy, low resolution). Time calculated in seconds since March 1st, 2000 at midnight.

To convert this raw number (`timestamp`) to a human readable form in `Matlab` use:   
`datetime(datevec(timestamp./86400 + datenum(2000,3,1,0,0,0)))`

#### Intuitive Approach to Deserializing RC+S Data

1. To guard against large-scale packet losses in which the `dataTypesequence` counter rolls-over (or the `systemTick` counter rolls-over), we track packet `timestamp`. A gap >= 6.5536 seconds in the successive `timestamp` of two files implies a large packet loss and triggers a re-initiation of our `systemTick` linearization algorithm.
	* For example, in our schematic above a large packet loss occurred between packets 5 and 117.
2. The `systemTick` time associated with each packet is the INS time of the last data sample in the packet.
	* The  `systemTick` timestamp of the first data sample in the packet can be calulated as follows: _Time First Sample_ = `systemTick` - (_Interstample Interval_ * (`data points` - 1))
	* The time for the other remaining data samples in the packet can be linearly interpolated by equidistant spacing of time between the `systemTick` time associated with the first and last data sample in each packet, respectively.
3. Packet losses with < 6.5536 seconds between successive timestamps can be captured by tracking the `dataTypesequence` counter (represented as `packet #` in our schematic above). 
	* For example, in our schematic above a small packet loss occurred between packets 2 and 4.
	* The number of lost data samples for a small packet loss can be calculated as follows:
		*

In above example, we are streaming data at 1000Hz. Our first packet (labeled `packet #` in figure, actually named `dataTypeSequence` in header) we stream packets 0-2 but then miss packet #3. This represents a small packet loss and we can compute how much time was lost by subtracting the time of the last sample in packet 4 from the last sample on packet 2 (7537-6539 = 998). Since the LSB on the `systemTick` is 100 microseconds, this represents a gap of 99.8 milliseconds. However, we have 25 data points in packet 4, at 1000Hz this is 25 milliseconds - so there is a 74.8 millisecond gap between packet 4 and packet 2. For cases in which the packet loss is larger than the system tick (as evident by the time stamp field incrementing by more than 6.5536 seconds) we can not use `systemTick` to compute time and rely on the `timestamp` field. This is what happens between packet 5 and 117. There are other ways to approach "unraveling" the data as well such as interpolation but this is the method we chose to implement here.

A fully commented algorithm for deserializing RC+S time domain data can be appreciated in the `Python` implementation by reading the comments (in sequential order) contained within the `extract_td_meta_data`, `code_micro_and_macro_packet_loss`, and `unpacker_td` functions.

Streaming modes in RC+S: 
-------------
A variety of factors influence the degree of packet loss one can expect with RC+S. These include packet size, the streaming mode (3/4 - 4 is better for streaming), ratio (the ratio of packets sent from INS to CTM vs commands sent from CTM to INS) and the number of data channels being acquired. During our benchmark testing we used mode 4, ratio 32, 50msec packets and streamed 2 time domain channels as well as IMU data. In this setting we achieve packet loss comprising around ~1% of the data in a 2 hour continuous recording under ideal bench-top conditions. 

Contents: 
-------------

* `python`    - Folder with Python code to read RC+S data 
* `Matlab` - Folder with Matlab code to do the same. see `MAIN` function to select TD file. 

To Do: 
-------------
* Add routines to process data folders 
* Consider implementing more efficient datetime storage (double rather than string) if human readability not important. 
* Backtrace first packet `timestamp` from a system rollover. 
* Consider using data that exists in TimeSync.json option.