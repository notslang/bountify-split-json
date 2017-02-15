# bountify-split-json

A little CLI script for <https://bountify.co/add-additional-output-functionality-to-existing-node-script>

# origional question on bountify

The following script currently MERGES multiple `.json` files into a single `.json` file, and it SPLITS single `.json` files into multiple `.json` files.

For SPLITTING, the file must contain records in the following (`\n`) newline format;

```
{"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName2","key2":"path/to/folder/2/","key3":"value3","key4":"value4","key5":"value5"}
```

It then outputs individual `.json` files in the same format as above.

## task #1

I need the script to prompt for an output choice, to output the above format (option 1), or to output the following format (option 2), wherein option 2 requires input from the user to give it a name (e.g.- userAddedKeyword as seen below);

```
{"userAddedKeyword": [
  {"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
  {"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
  {"key1":"fileName1","key2":"path/to/folder/2/","key3":"value3","key4":"value4","key5":"value5"}
]}
```

## task #2

Currently, the script using a key value from the JSON records themselves within the `.json` file, and the following is an example of running the script and using the key value of 'key1';

```
node script.js split "splitMe.json" key1 "output_folder/"
```

This takes all records with the same 'key1' value, and outputs them to their own singular `.json` file. So, if the splitMe.json file contains 10 records with the same 'key1' value, those 10 records will go into the same single output `.json` file. the same is true for all other records in the splitMe.json file. At the moment, it includes that 'key1' value in the output.

I need an option to include or omit that 'key1' value from the output. the 'key1' value is used for the purposes of naming the output files, and though sometimes that value is needed in the final output, other times it is not, because it is only used for the purposes of naming the file.

## task #3

At the moment, the script outputs all split files into the same designated folder, e.g.- `output_folder/`. I need an option to include the ability to output files to unique folders by using a second 'key2' value from the splitMe.json file, similar to how 'key1' is being used to name the file... 'key2' would be used to declare the output directory/path. Likewise, 'key2' values would need to be omitted from the actual `.json` file output. So, if splitMe.json looked like this;

```
{"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName1","key2":"path/to/folder/1/","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName2","key2":"path/to/folder/2/","key3":"value3","key4":"value4","key5":"value5"}
```

the records in the output `.json` files would look like this;

```
{"key1":"fileName1","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName1","key3":"value3","key4":"value4","key5":"value5"}
{"key1":"fileName2","key3":"value3","key4":"value4","key5":"value5"}
```

And if the user opted to omit the 'key1' value (used to name the `.json` files), then the records in the output `.json` files would look like this;

```
{"key3":"value3","key4":"value4","key5":"value5"}
{"key3":"value3","key4":"value4","key5":"value5"}
{"key3":"value3","key4":"value4","key5":"value5"}
```

And the output `.json` files would be here;

path/to/folder/1/fileName1.json. <<-- this `.json` file would contain 2 records

path/to/folder/2/fileName2.json. <<-- this `.json` file would contain 1 record

Below is a quick video I made showing how the script currently takes a splitMe.json file and outputs all of the records to their own uniquely named ('key1') `.json` files into a designated output_folder/:

<http://somup.com/cbnoiy8Yo>

Here is the script;

```
var fs = require("fs");
var action = process.argv[2];

if(action == "split"){
var filePath = process.argv[3];
var key = process.argv[4];
// Asynchronous read
fs.readFile(filePath, function (err, data) {
if (err) {
return console.error(err);
}
var lines = data.toString().split("\n");
// determine the input type
var type = "ndjson";
// Note: The comma at the end of the line is optional. I assume the format
// is [{object}],\n[{object}],\n[{object}]\EOF
if (lines[0].match(/[[]]*],?/)) {
// it's the JSON-style format [<json>],
type = "json";
}
var out = "";
for (var i = 0; i < lines.length; i++) {
if (lines[i].trim() == "") {
continue;
}
var json;
if (type == "ndjson"){
json = JSON.parse(lines[i]);
}
else if (type == "json") {
json = JSON.parse(lines[i].match(/[([]]*)],?/)[1]);
}
fs.appendFile(
process.argv[5] + "/" + json[key] + ".json",
JSON.stringify(json) + "\n",
function(){} // supresses warning
);
}
});
}
else if (action == "merge") {
var data;
// get the desired output format from the user
getFormat(function(format){
if (Number(format) == 3 && process.argv.length < 6){
console.log("You forgot to declare an index (e.g.- pid) at EOL, run script again.");
process.exit();
}
var index = process.argv[5];
var mergedString = "";
var items = fs.readdirSync(process.argv[3]);
for (var i = 0; i < items.length; i++) {
if (items[i].endsWith(".json")){
data = fs.readFileSync(process.argv[3] + '/' + items[i], "utf8");
for (var a in data.toString().split("\n")) {
var item = data.toString().split("\n")[a];
if (item != ""){
switch (Number(format)) {
case 1: // minified JSON
mergedString = mergedString + "[" + item + "],\n";
break;
case 2: // NDJSON
mergedString += item + "\n";
break;
case 3: // ESJSON
mergedString += '{"index":{"_id":"' +
JSON.parse(item)[index] +
'"}}\n' +
item +
"\n";
break;
default:
break;
}
}
}
}
}
var writeStream = fs.createWriteStream(process.argv[4]);
writeStream.write(mergedString);
writeStream.end();
writeStream.on("finish", function(){
process.exit();
});
});
}
else {
console.log("Please provide a correct action");
}

// function to use recursion to simulate syncronous access to stdin/out
function getFormat(callback){
process.stdout.write(
"Select output format: 1:minified JSON, 2: NDJSON, 3:ESJSON: "
);
process.stdin.setEncoding('utf8');
process.stdin.once('data', function(val){
// check validity of input
if (!isNaN(val) && 0 < Number(val) < 3){
callback(val);
}
else {
// if input is invalid, ask again
getFormat(callback);
}
}).resume();
}
```
