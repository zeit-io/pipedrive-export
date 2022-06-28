# Pipedrive Export

This project exports data from Pipedrive, using the official Pipedrive API. 
The special thing on this exporter is that it exports the data related to a Pipeline. You configure the API token and the name of the Pipeline and this script will export all deals, notes and emails which are related to the configured pipeline. 

## API Tokne 

Get your API token from your Pipedrive account and set it as ENV variable like this: 

```
export TOKEN=<YOUR_TOKEN>
```

## Pipeline name 

You can configure the name of the Pipeline in the Rakefile, in line 11. 

## Run the export 

You can run the export with this command: 

```
rake pipe_export
```

This will export the data to json files into the exports directory. 

## License 

This project is under MIT license. 
