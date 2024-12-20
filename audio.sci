// Load the audio file
wav_file = 'D:\sample.wav';

// Read WAV file information
wav_info = wavread(wav_file, "info");
wav_info_string = [
    'WAV encoding code: ',
    'WAV number of channels: ',
    'WAV sampling frequency (in Hz): ',
    'WAV average bytes per second: ',
    'WAV block alignment: ',
    'WAV bits per sample (per channel): ',
    'WAV bytes per sample (per channel): ',
    'WAV length of sound data (per channel): '
];

// Display WAV file information
for i = 1:8
    disp(wav_info_string(i), wav_info(i));
end

// Load the WAV data
[signal, Fs, nbits] = wavread(wav_file);
signal = signal(1,:);

// Visualize the signal in the time domain
subplot(221);
plot2d(signal(1,:));
xlabel('Time (samples)');
ylabel('Amplitude');
title('Signal sample.wav in Time Domain');

// Compute the Fourier Transform for the signal
Y = fft(signal(1,:));

// Compute the length of the data
N = length(Y);

// Compute the frequency domain
f = Fs * (0:(N/2)) / N;

// Compute the magnitude of the Fourier Transform
P2 = abs(Y / N);
P1 = P2(1:N/2+1);
P1(2:$-1) = 2 * P1(2:$-1);

// Plot the signal in the frequency domain
subplot(222);
plot2d(f, P1);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Signal sample.wav in Frequency Domain (FFT)');

// Set FIR filter order and cutoff frequency
order = 100; // Order of the FIR filter
cutoff_freq = 500; // FIR Filter cutoff frequency in Hz

// Low-pass FIR filter using cutoff frequency 500Hz
h = zeros(1, order + 1);
for i = 1:order + 1
    if i == (order + 1) / 2
        h(i) = 2 * cutoff_freq / Fs;
    else
        h(i) = sin(2 * %pi * cutoff_freq * (i - 1) / Fs) / ((i - 1 - (order + 1) / 2) * %pi);
    end
end

// Normalize the filter coefficients
h = h / sum(h);

// Apply FIR filter with convolution
y_filtered = conv(signal, h, 'same');

// Plot the filtered signal in the time domain
subplot(223);
plot2d(y_filtered(1,:));
xlabel('Time (samples)');
ylabel('Amplitude');
title('Signal sample.wav in Time Domain (Filtered)');

// Compute the Fourier Transform for the filtered signal
Y_filtered = fft(y_filtered(1,:));

// Compute the length of the filtered data
N_filtered = length(Y_filtered);

// Compute the frequency domain of the filtered signal
f_filtered = Fs * (0:(N_filtered/2)) / N_filtered;

// Compute the magnitude of the Fourier Transform of the filtered signal
P2_filtered = abs(Y_filtered / N_filtered);
P1_filtered = P2_filtered(1:N_filtered/2+1);
P1_filtered(2:$-1) = 2 * P1_filtered(2:$-1);

// Plot the filtered signal in the frequency domain
subplot(224);
plot2d(f_filtered, P1_filtered);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Signal sample.wav in Frequency Domain (Filtered FFT)');

// Save the filtered signal into a WAV file
output_wav_file = 'D:\sampleoutput.wav';

// Write the filtered signal to a WAV file
wavwrite(y_filtered', Fs, output_wav_file);
