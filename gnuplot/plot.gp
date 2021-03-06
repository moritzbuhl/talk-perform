#!/usr/local/bin/gnuplot

# Copyright (c) 2018-2019 Moritz Buhl <mbuhl@genua.de>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# plot test results, the following variables are required:
# DATA_FILE	Path,	plot data file, space separated,
#			format: "test subtest run checkout repeat value unit"
# TESTS		String,	testnames to filter and plot, space separated,
#			format: "test1 subtest1 test2 sub2 ... testN subN"
#
# The following variables are optional:
# QUIRKS	String, format: "date1 descr1 date2 descr2 ... dateN descrN"
# RUN_DATE	UNIX time stamp, filter for a "run" value
# TITLE		String,	plot title
# UNIT		String, unit for the y-axis

if (!exists("DATA_FILE") || !exists("OUT_FILE") || !exists("TESTS")) {
    exit error "Please define DATA_FILE, OUT_FILE and TESTS."
    exit status 1
}

set datafile separator whitespace

if (!exists("TITLE")) { TITLE = "" }
if (!exists("UNIT")) { UNIT = "" }
if (!exists("QUIRKS")) { QUIRKS = "" }

stats DATA_FILE using 4:6 nooutput
st_max_y = STATS_max_y

if (exists("RUN_DATE")) {
    stats DATA_FILE using 4:(strcol(3) eq RUN_DATE? $6:NaN) nooutput
}

# If there are not data points, create an empty image to prevent future gnuplot
# invocations. To prevent warnings, set most style settings after this check.
if (!exists("STATS_records")) {
    set terminal png size 240,80
    set title TITLE."\nNO DATA" offset first 0,0
    set yrange [-1:1]
    unset tics
    unset border
    plot 0 lc rgb 'white'
    exit
}

set xrange[STATS_min_x - 1 : STATS_max_x + 1] # work around min == max
set yrange[0 : st_max_y]
set title TITLE
set ylabel UNIT
set format x "%Y-%m-%d"
set timefmt "%s"
set xdata time
set xlabel "Checkout (date)"
set tics out
set border 3
set output OUT_FILE
set terminal epslatex color size 17, 10
#set terminal png transparent size 1360, 768
unset key

# draw quirks
#set style textbox opaque noborder fillcolor rgb "white"
lbl_index = 1
do for [i = 1:words(QUIRKS)] {
    XPOS = (int(word(QUIRKS, i))-STATS_min_x)/(STATS_max_x-STATS_min_x+1)
    if (XPOS > 0 && XPOS < 1) {
	DESCR = sprintf("%c", (64 + lbl_index))
	set arrow from graph XPOS,0 to graph XPOS,1 nohead lw 1 lc rgb 'black'
	set label DESCR at graph XPOS, graph 1 noenhanced \
	    offset character -.5, character 0.7 front
    }
    if (lbl_index == 26) { # jump from Z to a
	lbl_index = lbl_index + 6
    }
    lbl_index = lbl_index + 1
}

# draw data
if (exists("RUN_DATE")) {
    plot for [test = 1:words(TESTS):2] DATA_FILE using 4:( \
	strcol(3) eq RUN_DATE? ( \
	    strcol(1) eq word(TESTS,test)? ( \
		strcol(2) eq word(TESTS,test+1)? $6:NaN \
	    ):NaN \
	):NaN \
    ) title word(TESTS,test)." ".word(TESTS,test+1) noenhanced ps 10
} else {
    plot for [test = 1:words(TESTS):2] DATA_FILE using 4:( \
	strcol(1) eq word(TESTS,test)? ( \
	    strcol(2) eq word(TESTS,test+1)? $6:NaN \
	):NaN \
    ) title word(TESTS,test)." ".word(TESTS,test+1) noenhanced ps 10
}
