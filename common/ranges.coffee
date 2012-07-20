###

This adds support to etherpad documents to assign properties to ranges
of text without copying these properties to each characted in particular
For example, if some text range needs to be bold (offset, length), it is 
suboptimal to have the bold property assigned to each characted in that range. 
Rather, one would add a property (".bold", true) to the position offset
and a property ("range.bold", false) to offset+length+1

1) application of changeset applies?

add range bold (1,5)

1	2	3	4	5
(rb,T)				(rb, false)


2) 

###
