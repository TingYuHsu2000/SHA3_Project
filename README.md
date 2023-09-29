# SHA3_Project
2023/9
ES113
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
