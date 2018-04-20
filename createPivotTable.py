# The following code creates a pivot or fallow acreage summary table.
# Created by Carolyn Rosevelt, NASA-Ames/CSUMB Cooperative 02/14/18



# Import libraries and read-in FAM output csv file.
import json, csv, sys, os
import pandas as pd
import numpy as np

usage = "Creates a pivot table of the appended reclassified CDL file. To add or omit counties of interest open the pivotTablesConfig.json file and edit it\n" + \
        "usage: python pivotTables.py <Directory path of appended reclassified file> <Directory path of the .json config file"

if len(sys.argv) < 1:  #number of arguments required
    print usage
    sys.exit(1)

# Set working directory to user input (directory path of input files)
os.chdir(sys.argv[1])

with open(sys.argv[2] +'\pivotTableConfig.json') as json_data_file:
    data = json.load(json_data_file)

countyList = []

for item in data['county_list']:
    print item
    countyList.append(item)

print countyList

inputFileName = sys.argv[1]+"\Appended_reclass.csv"
outputFileName = sys.argv[1]+"\Appended_reclass_county.csv"
remove_words = countyList

with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    for line in r:
        if not any(remove_word in element
                      for element in line
                      for remove_word in remove_words):
                            w.writerow(line)



# Read-in merged csv file and convert to excel.
df = pd.read_csv(sys.argv[1]+"\Appended_reclass_county.csv",  dtype={"CVPM": str})


# Creates pivot table that indexes county name 'COUNTY' from the previously merged file and summarizes idle vs. cropped acreage.
table = pd.pivot_table(df, index=["COUNTY"], values=["AcresMast"], columns=["S20160720"], aggfunc=[np.sum], fill_value=0, margins=True)
print 'table created'

# Changes column headers and assigns new names.
table.columns = ['Idle', 'Rice', 'Alfalfa', 'Cropped', 'NaN', 'Total']
print 'table columns changed'

# Formats values of acres 'AcresMast' to include commas yet keeps the float format of that variable.
pd.options.display.float_format = '{:,.0f}'.format
print 'added commas'

# prints out table, but does not save it yet.
print table

# Writes and saves table to new excel workbook, a singlular table with fallow acreage county summaries.
writer = pd.ExcelWriter(sys.argv[1]+"\Pivot_CA_COUNTIES_2016.xlsx")
print 'wrote new file'

temp_df = table

temp_df.to_excel(writer)

writer.save()

os.remove('Appended_reclass_county.csv')
