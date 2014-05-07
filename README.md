# Rimpact

## Description

Rimpact allows your Ruby on Rails application to parse bibliographic data in [BibTeX](http://en.wikipedia.org/wiki/BibTeX),  [RIS](http://en.wikipedia.org/wiki/RIS_(file_format)), or [EndNote Export](http://wiki.cns.iu.edu/pages/viewpage.action?pageId#1933370) formats and generate [d3.js](http://d3js.org/) based visualization graphs.


## Configuring your Rails application

Take the following steps to configure your Rails application to use Rimpact.

Add the following lines to the +Gemfile+:

    gem 'gnlookup', :git => 'https://github.com/lw292/gnlookup.git'
    gem 'rimpact', :git => 'https://github.com/lw292/rimpact.git'

If you are running Rails 4.x, you will also need this line in the +Gemfile+:

    gem 'protected_attributes'

Then use the +bundle+ command to install the gems and their dependencies:

    bundle install

You will need to create some required files and directories in your application. You can do so by running:

    rake rimpact:setup

This will create the following empty directories and files (if they do not already exist):

    public/data
    public/external
    public/results
    public/preferred
    public/preferred/cities.csv
    public/preferred/regions.csv


## Acquiring Reference Data

Rimpact has been tested to work with reference data directedly exported from Scopus in the BibTeX and RIS formats. For most other bibliographic databases, such as PubMed, the OvidSP databases, the Web of Knowledge databases, or if you are using data retrieved from more than one databases, it is recommended that you first export data to a citation management application, such as EndNote or RefWorks. You can then use these applications to clean the data (see the "Cleaning Reference Data" section below) and then export to one of the supported formats (BibTeX, RIS, or EndNote Export).


#### From Scopus

1. Go to [Scopus](http://www.scopus.com/). If you do not have access, please contact your librarian.
2. Run your search to get a result set.
3. Select the references you would like to export.
4. Click the "Export" icon. Notice if you want to export all references in the set (and not only those on the first page), you may need to choose that in the drop-down menu.
5. In the popup, choose "BibTeX" or "RIS" format.
6. In the dropdown, choose "Specify fields to be exported". Then select the fields. Normally you should choose all fields under "Citation information" and the "Affiliations" field under "Bibliographical information". Please note that the "Source and Document Type" field under "Citation information" is REQUIRED for the RIS format.
7. Click "Export", and the data file will be downloaded to your browser's download location, with the default file name "scopus.bib" or "scopus.ris".
8. Copy the downloaded data file to your application's +public/data+ directory. Rename it if you wish. Typically, you would end up having a file like these:

    public/data/scopus.bib
    public/data/scopus.ris

#### From EndNote

1. Run your search in your favorite databases, and export references to EndNote. See instructions for some databases here: [PubMed](http://library.medicine.yale.edu/guides/screencasts/endnote_tt/pubmed_export/), [OvidSP](http://library.medicine.yale.edu/guides/screencasts/ovidsp/ovidsp_6_new/), and [CINAHL](http://library.medicine.yale.edu/guides/screencasts/cinahl/new_cinahl_8/). Refer to the manual of your database for instructions on how to export to EndNote.
2. Clean the references in EndNote. See the "Cleaning Reference Data" section below.
3. Select the references you wish to export.
4. Go to "File", "Export".
5. Navigate to a location where you wish to save the exported file, and choose a file name.
6. In Output Style drop-down, for RIS format, choose "RefMan (RIS) Export", for EndNote Export format, choose "EndNote Export", and for BibTeX format, choose "BibTeX Export" (See section below on "Using the BibTeX format"). If the style you need is not available in the dropdown, find it using "Select Another Style".
7. Click "Save".
8. Move the exported file to your application's "public/data" directory.

#### From RefWorks

1. Run your search in your favorite databases, and export references to RefWorks. See instructions for some databases here: [PubMed](http://library.medicine.yale.edu/guides/screencasts/endnote_tt/pubmed_export/), [OvidSP](http://library.medicine.yale.edu/guides/screencasts/ovidsp/ovidsp_7_new/), and [CINAHL](http://library.medicine.yale.edu/guides/screencasts/cinahl/new_cinahl_7/). Refer to the manual of your database for instructions on how to export to RefWorks.
2. Clean the references in RefWorks. See the "Cleaning Reference Data" section below.
3. Select the references you wish to export.
4. Go to "References", "Export".
5. At "Select an export format", for RIS format, choose "Bibliographic Software", and for BibTeX format, choose "BibTeX - RefWorks ID".
6. Click "Export References", and the data file will be downloaded to your browser's download location.
7. Move the exported file to your application's "public/data" directory.

#### Using the BibTeX format

The EndNote "BibTeX Export" style does not by default include author affiliation information, which is critical for generating geolocation-based visualization graphs. You can modify the "BibTeX Export" style to include the author affiliation information. Here is how:

1. Go to "Edit", "Output Styles", "Open Style Manager".
2. Search for the "BibTeX Export" style, and click "Edit".
3. Under "Bibliography", "Templates", for each of the appropriate reference types, add a line for "affiliation", extracting data from EndNote's "Author Address" field. Follow the syntax of existing lines.
4. Save as a new style. From this point on, you can use this style for exporting to BibTeX format.

The EndNote "BibTeX Export" style also relies on the "Label" field to generate the required citation keys in BibTeX format, but often times references retrieved from bibliographic databases have empty label fields. This causes those references to have empty keys when exported, which in turn causes some BibTeX parsing programs to break.

RefWorks uses its own ReferenceID field as the citation key when exporting to BibTeX, which should be unique if all the data in your BibTeX file are from the same RefWorks account.

If your exported BibTeX records have missing or duplicate keys, you can use the very handy [JabRef](http://jabref.sourceforge.net/) tool to auto-generate keys.

## Cleaning Reference Data

Your visualization is only as good as the accuracy of the reference data it is based on. The reference data you download from online databases is unfortunately very likely to contain ambiguities, inconsistencies, and sometimes even errors. You should use applications such as EndNote, RefWorks, or any editing tool you are comfortable with, to clean up the data before generating the visualization. The cleaning process usually involves disambiguation, resolving inconsistencies, error checking, and deduplication.

EndNote and RefWorks have the very useful "Find and Replace" funtion, which can help you batch modify your data. In EndNote, go to "Edit", and "Find and Replace". In RefWorks, click on the "Global Edit" icon, and expand the "Replace" section in the popup box.

Here are some common problems to pay attention to when you are trying to clean your data:

#### Ambiguous Author Names

Are there more than one authors that have the same name? For example:

    Shepherd, G # The senior
    Shepherd, G # The junior
	
#### Inconsistent Author Names

Are there authors that have more than one names in your data? For example:

    Smith, J # Last name with first name initial
    Smith, JD # Last name with both initials
    Smith, John # Last name with first name spelled out
    Smith, John D # Last name with first name spelled out and middle initial
    Smith, John David # Last name with both first and middle names spelled out
    
    Grossetta, Holly # Maiden name
    Nardini, Holly Grossetta # Name changed after marriage

#### Ambiguous Place Names

Are there addresses that refer to more than one places in the world? For example:

    London # Could be "London, England, United Kingdom" or "London, Ontario, Canana"
    New Haven, United States # Could be "New Haven, Michigan, United States" or "New Haven, Connecticut, United States"
	
#### Inconsistent Place Names

Are there places that have more than one names in your data? For example:

    CT, ct, Conn., Connecticut
    USA, U.S.A., United States, United States of America, US, U.S.
	
#### Multi-valued Fields

Rimpact will recognize common value delimiters in multi-valued fields, such as semicolons(;) and new line characters. Your data may use a different delimiter character, such as the pipe character (|):

    Smith, JD | Jone, AD | ...
    Yale University, New Haven, Connecticut, United States | Stanford University, Stanford, California, United States | ...

In that case, you can either change your data (using a program such as EndNote) so that values in multi-valued fields are delimited by semicolons or new line characters, or you can change your code so that it will accomodate these special delimiter characters.

#### Duplicate References

If you obtain your references from different sources, there will likely be duplicates in your data. You should try your best to remove the duplicates so that your visualization is as accurate as it can be. Citation management programs such as EndNote and RefWorks have "Find Duplicates" features, but please note that due to the subtle differences in the references data from different sources, these programs may not be able to find all duplicates.


## Transforming and Visualizing Reference Data

Once you have a clean, consistent, and non-ambiguous set of references, you can use Rimpact to generate visualization graphs. The algorithms for generating visualization graphs are encapsulated as "recipes" under the +lib/recipes+ directory. At this point, only two recipes are included. Each recipe has its own rake tasks. To see what tasks are available, run the following command and look for tasks that start with "rimpact":

    rake -T

You can create your own custom recipes following the example of the included recipes. If you would like to contribute your recipes to us, please let us know so that we can add them to Rimpact.

#### The Authors Recipe

The +authors+ recipe generates [force-directed graphs](http://en.wikipedia.org/wiki/Force-directed_graph_drawing) of author collaboration networks. To do that, run:

    rake rimpact:authors:create

This will parse your data file, extract the author fields, calculate the number of collaborators and publications for each author, and generate the html, JavaScript and data required to display the force-directed graph.

All generated files will be saved to the path you specify when you run the task. Typically, if you follow the conventions, you would end up having this directory in your +public/results+ directory:

    public/results/your_project_name/authors

The directory is a self contained system. You can drop it on to any web server, and point your browser to the +index.html+ file to view it. If you want to use your Rails application to view it, start your Rails server, and point your browser to:

    http://your_rails_server_root_url/results/your_project_name/authors/index.html

#### The Geo Recipe

The +geo+ recipe generates graphs of geographical collaboration networks.

###### Setting Up Gnlookup

The +geo+ recipe relies on a service from which latitudes and longitudes of cities can be retrieved. The Gnlookup gem will provide that service. Please follow [this guide](https://github.com/lw292/gnlookup) to set it up for your Rails application.

###### Getting Map Data

In order for the browser to display maps, you will need the map shape data for the United States and the world in [geojson format](http://en.wikipedia.org/wiki/GeoJSON). Please follow [this guide](http://chimera.labs.oreilly.com/books/1230000000345/ch12.html#_acquiring_and_parsing_geodata) to generate these data files and place them in the +public/external+ directory. You should end up having these files:

    public/external/geo/us.json
    public/external/geo/world.json

###### Using the Geo Recipe

To create a graph of geographical collaboration networks from the data, run:

    rake rimpact:geo:create

This will parse your data file, extract the affiliation / address fields, and for each address, try to determine the latitude and longitude of the address at city level. This will generate the html, JavaScript and data required to display the graphs of geographical collaboration networks.

All generated files will be saved to the path you specify when you run the task. Typically, if you follow the conventions, you would end up having this directory in your +public/results+ directory:

    public/results/your_project_name/geo

Again the directory is a self contained system. You can drop it on to any web server, and point your browser to the +index.html+ file to view it. If you want to use your Rails application to view it, make sure your Rails server is running, and point your browser to:

    http://your_rails_server_root_url/results/your_project_name/geo/index.html

###### Ambiguous US Cities

As mentioned above in the "Cleaning reference data" section, place name ambiguity occurs if there are missing parts in the address. For example, "New Haven, United States" could be any one of these:

    New Haven, Connecticut, United States
    New Haven, Indiana, United States
    New Haven, Michigan, United States

Such ambiguity is more likely to exist for United States addresses because a lot of authors omit state information in their addresses.

If you do not disambiguate these addresses, Rimpact will simply skip those addresses and will NOT try to make a decision for you automatically.

However, you can get a list of such skipped US addresses by running:

    rake rimpact:geo:check

This will generate a number of files in your results directory including the "ambiguous_cities.csv" file. You can now manually disambiguate these cities. To do that, replace each line with the correct city and state information in this format:

    New Haven, CT
    Philadelphia, PA
    Anytown, AL

You only need to include the city and state (2-letter code uppercase), and you only need to include each city once.

After that, you can add these cities to your "preferred cities" list:

    rake rimpact:geo:preferred

This will help Rimpact make a decision next time when such ambiguity occurs. For example, next time when it sees "New Haven, United States", it will know that "New Haven, CT" is your preferred city among all the "New Havens" in the United States, and therefore it will map that address to "New Haven, Connecticut, United States".

After you update your preferred cities list, you should run this task again to update your graph:

    rake rimpact:geo:create


## License

This project rocks and uses MIT-LICENSE.