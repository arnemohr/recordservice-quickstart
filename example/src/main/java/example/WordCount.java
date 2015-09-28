// Copyright 2012 Cloudera Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package example;

import java.io.IOException;
import java.util.Iterator;
import java.util.StringTokenizer;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.FileInputFormat;
import org.apache.hadoop.mapred.FileOutputFormat;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reducer;
import org.apache.hadoop.mapred.Reporter;
import org.apache.hadoop.mapred.TextOutputFormat;

import com.cloudera.recordservice.mr.RecordServiceConfig;

/**
 * Implementation of word count using the RecordService version of TextInputFormat.
 * This is intended to look as closely as possible to the standard WordCount
 * implementation.
 */
public class WordCount {
  public static class Map extends MapReduceBase
      implements Mapper<LongWritable, Text, Text, IntWritable> {
    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    /**
     * Map task which tokenizes 'value' and outputs each tokenized word.
     */
    public void map(LongWritable key, Text value,
        OutputCollector<Text, IntWritable> output, Reporter reporter)
        throws IOException {
      String line = value.toString();
      StringTokenizer tokenizer = new StringTokenizer(line);
      while (tokenizer.hasMoreTokens()) {
        word.set(tokenizer.nextToken());
        output.collect(word, one);
      }
    }
  }

  public static class Reduce extends MapReduceBase
      implements Reducer<Text, IntWritable, Text, IntWritable> {

    /**
     * Reduce task that just sums up the occurrences of each word ('key')
     */
    public void reduce(Text key, Iterator<IntWritable> values,
        OutputCollector<Text, IntWritable> output, Reporter reporter)
        throws IOException {
      int sum = 0;
      while (values.hasNext()) {
        sum += values.next().get();
      }
      output.collect(key, new IntWritable(sum));
    }
  }

  public void run(String[] args) throws Exception {
    if (args.length != 2) {
      System.err.println("Usage: WordCount <input path> <output path>");
      System.exit(-1);
    }
    String input = args[0].trim();
    String outputPath = args[1];

    JobConf conf = new JobConf(WordCount.class);
    conf.setJobName("wordcount");

    conf.setOutputKeyClass(Text.class);
    conf.setOutputValueClass(IntWritable.class);

    conf.setMapperClass(Map.class);
    conf.setCombinerClass(Reduce.class);
    conf.setReducerClass(Reduce.class);

    conf.setOutputFormat(TextOutputFormat.class);
    FileOutputFormat.setOutputPath(conf, new Path(outputPath));

    /**
     * Below are the modifications to use RecordService.
     * First, we set the InputFormat to the RecordService equivalent of
     * TextInputFormat
     */
    conf.setInputFormat(com.cloudera.recordservice.mapred.TextInputFormat.class);

    /**
     * Next, we specify the input. RecordService supports additional ways
     * of specifying input compared to the standard FileInputFormats.
     *
     * If the input starts with "select", assume this is a query. This is where the
     * application can pass predicates to the RecordService server.
     *
     * If the input starts with '/', assume it is just a path request. This is
     * identical to a normal FileInputFormat.
     *
     * Otherwise, assume it is a scan for entire table.
     */
    if (input.toLowerCase().startsWith("select")) {
      RecordServiceConfig.setInputQuery(conf, input);
    } else if (input.startsWith("/")) {
      FileInputFormat.setInputPaths(conf, new Path(input));
    } else {
      RecordServiceConfig.setInputTable(conf, null, input);
    }

    JobClient.runJob(conf);
  }

  public static void main(String[] args) throws Exception {
    new WordCount().run(args);
    System.out.println("Done");
  }
}
