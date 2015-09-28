# RecordServiceExample

This repository contains a simple WordCount example using the RecordService java 
client libraries. This includes the pom setup as well as reimplementation of the
popular Hadoop WordCount example.

To run the example, add
recordservice-core-0.1.jar and
recordservice-mr-0.1.jar
to your HADOOP_CLASSPATH. 

Then run:
hadoop jar wordcount-1.jar example.WordCount

