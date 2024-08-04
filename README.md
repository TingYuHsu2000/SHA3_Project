# SHA3_Project
2023/9
ES113

## Abstract
The importance of information privacy and data protection has grown significantly in modern society. Cryptography, as one of the key technologies for safeguarding the digital world, has been extensively researched in academia. Additionally, ensuring data security is significant within the realm of virtual currencies. To achieve this, hash functions, specifically utilizing the SHA-3 algorithm, are employed to generate hash values for storing user-defined passwords. The irreversibility of hash values enhances the security of virtual currency data. 

In this research project, Verilog is utilized as the primary compiled language due to its advantages in hardware description over software languages. Hardware description languages(HDL) offer higher speed, concurrent execution of multiple operations, and reduced processing time, resulting in increased efficiency.

The SHA-3 algorithm comprises two distinct modes: the Cryptographic Hash Functions including SHA3-224, SHA3-256, SHA3-384, and SHA3-512, with the appended twice numbers denoting their specified capacity lengths, and the Extendable-Output Functions (XOF) comprising SHAKE128 and SHAKE256, allowing for output lengths customized with the following twice numbers representing the capacity length of each mode. 

This study involves the implementation of four different algorithms with varying modes and capacity lengths: SHA3-256, SHA3-512, SHAKE128, and SHAKE256. 
The completed SHA-3 circuits undergo RTL and Gate-Level simulations using Cadence's NC-Verilog, and debugging is carried out using Synopsys' Verdi tool. 

Subsequently, synthesis is performed using Design Compiler with a clock cycle of 6.5 ns and a TSMC 40nm fabrication process, following multiple iterations. The final cell base area is 614853.872096 μm².

Keywords: SHA-3, Sponge Structure, Pipeline

## SHA I/O interface description
| Signal Name | I/O | Width(bits) | Description |
| :--------: | :--------: | :--------: | :-------- |
| clk     | I     | 1     | Clock Signal (positive edge trigger)     |
| rst     | I     | 1     | Asynchronous reset signal (active high)     |
| mode_in     | I     | 2     | 選擇要執行的SHA3模式<br>2'd0：SHA3-256<br>2'd1：SHA3-512<br>2'd2：SHAKE-128<br>2'd3：SHAKE-256     |
| data_in     | I     | 6400     | 輸入之要執行SHA3運算的message     |
| data_len     | I     | 13     | 本次輸入data_in的有效長度     |
| length     | I     | 13     | 輸出之hash value的長度(只有當模式為SHAKE的時候length才可調整)|
| in_finish     | I     | 1     | 當本次要進行SHA3運算的最後的message輸入完成後，會同時將此訊號設為high     |
| in_valid     | I     | 1     | 當要進行SHA3的輸入值為有效，將此訊號設為high     |
| data_out     | O     | 1344     | 輸出之經過SHA3運算的hash value     |
| mode_out     | O     | 2     | 輸出之hash value是透過哪一種mode進行運算的     |
| out_valid     | O     | 1     | 輸出有效訊號，當要輸出時要將此訊號設為high     |
| out_length     | O     | 11     | 本次輸出之hash value的有效長度     |
| finish     | O     | 1     | 當本次進行完SHA3運算的最後的hash value輸出完成後，須將此訊號設為high     |
