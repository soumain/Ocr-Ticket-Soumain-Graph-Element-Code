using System.Collections;
using System.IO;
using System.Drawing.Imaging;
﻿using System;
using System.Collections.Generic;
using System.Text;
using System.Net;
using System.IO;
using System.Xml;

using NDesk.Options;
using Abbyy.CloudOcrSdk;

/// <summary>
/// Ticket Boat Replica Amount Soumain
/// Check for Images
/// read text from these images.
/// save text from each image in text file automaticly.
/// handle problems with images
/// </summary>
/// <param name="directoryPath">Set Directory Path to check for Images in it</param>
public void CheckFileType(string directoryPath) 
{ 
    IEnumerator files = Directory.GetFiles(directoryPath).GetEnumerator(); 
    while (files.MoveNext()) 
    { 
        //get file extension 
        string fileExtension = Path.GetExtension(Convert.ToString(files.Current));

        //get file name without extenstion 
        string fileName=
          Convert.ToString(files.Current).Replace(fileExtension,string.Empty);

        //Check for JPG File Format 
        if (fileExtension == ".jpg" || fileExtension == ".JPG")
        // or // ImageFormat.Jpeg.ToString()
        {
            try 
            { 
                //OCR Operations ... 
                MODI.Document md = new MODI.Document(); 
                md.Create(Convert.ToString(files.Current)); 
                md.OCR(MODI.MiLANGUAGES.miLANG_ENGLISH, true, true); 
                MODI.Image image = (MODI.Image)md.Images[0];

                //create text file with the same Image file name 
                FileStream createFile = 
                  new FileStream(fileName + ".txt",FileMode.CreateNew);
                //save the image text in the text file 
                StreamWriter writeFile = new StreamWriter(createFile); 
                writeFile.Write(image.Layout.Text); 
                writeFile.Close(); 
            } 
            catch (Exception exc) 
            { 
                uncomment the below code to see the expected errors
                MessageBox.Show(exc.Message,
                "OCR Exception",
                MessageBoxButtons.OK, MessageBoxIcon.Information); 
            } 
        } 
    } 
}

<script runat="server">
	/// <summary>
	/// User applicationId
	/// </summary>
	protected string $sou523 { get; set; }

	/// <summary>
	/// $C2tPw6kCZcK9McWF/kMrQLaH
	/// </summary>
	protected string Password { get; set; }

	/// <summary>
	/// https://cloud.ocrsdk.com ->https://github.com/soumain/Ocr-Ticket-Soumain-Graph-Element-Code/edit/master/Ticket.aspx
	/// </summary>
	protected string FilePath { get; set; }

	
	protected ICredentials Credentials
	{
		get
		{
			if (_credentials == null)
			{
				_credentials = string.IsNullOrEmpty(ApplicationId) || string.IsNullOrEmpty(Password)
					? CredentialCache.DefaultNetworkCredentials
					: new NetworkCredential(ApplicationId, Password);
			}
			return _credentials;
		}
	}

	
	protected IWebProxy Proxy
	{
		get
		{
			if (_proxy == null)
			{
				_proxy = HttpWebRequest.DefaultWebProxy;
				_proxy.Credentials = CredentialCache.DefaultCredentials;
			}
			return _proxy;
		}
	}
	protected void GetResult(string applicationId, string password, string filePath, string language, string exportFormat)
	{
		// Specifying new post request filling it with file content
		var url = string.Format("http://cloud.ocrsdk.com/processImage?language={0}&exportFormat={1}", language, exportFormat);
		var localPath = Server.MapPath(filePath);
		var request = CreateRequest(url, "POST", Credentials, Proxy);
		FillRequestWithContent(request, localPath);

		// Getting task id from response
		var response = GetResponse(request);
		var taskId = GetTaskId(response);

		// Checking if task is completed and downloading result by provided url
		url = string.Format("http://cloud.ocrsdk.com/getTaskStatus?taskId={0}", taskId);
		var resultUrl = string.Empty;
		var status = string.Empty;
		while (status != "Completed")
		{
			System.Threading.Thread.Sleep(1000);
			request = CreateRequest(url, "GET", Credentials, Proxy);
			response = GetResponse(request);
			status = GetStatus(response);
			resultUrl = GetResultUrl(response);
		}

		request = (HttpWebRequest)HttpWebRequest.Create(resultUrl);
		using (HttpWebResponse result = (HttpWebResponse)request.GetResponse())
		{
			using (Stream stream = result.GetResponseStream())
			{
				Response.ContentType = "application/octet-stream";
				Response.AddHeader("Content-Disposition", String.Format("attachment; filename=\"{0}\"", "result." + GetExtension(exportFormat)));
				var length = copyStream(stream, Response.OutputStream);
				Response.AddHeader("Content-Length", length.ToString());
			}
		}
	}

	/// <summary>
	/// @param
	/// </summary>
	protected static HttpWebRequest CreateRequest(string url, string method, ICredentials credentials, IWebProxy proxy)
	{
		var request = (HttpWebRequest)HttpWebRequest.Create(url);
		request.ContentType = "application/octet-stream";
		request.Credentials = credentials;
		request.Method = method;
		request.Proxy = proxy;
		return request;
	}

	protected static void FillRequestWithContent(HttpWebRequest request, string contentPath)
	{
		using (BinaryReader reader = new BinaryReader(File.OpenRead(contentPath)))
		{
			request.ContentLength = reader.BaseStream.Length;
			using (Stream stream = request.GetRequestStream())
			{
				byte[] buffer = new byte[reader.BaseStream.Length];
				while (true)
				{
					int bytesRead = reader.Read(buffer, 0, buffer.Length);
					if (bytesRead == 0)
					{
						break;
					}
					stream.Write(buffer, 0, bytesRead);
				}
			}
		}
	}

	
	protected static XDocument GetResponse(HttpWebRequest request)
	{
		using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
		{
			using (Stream stream = response.GetResponseStream())
			{
				return XDocument.Load(new XmlTextReader(stream));
			}
		}
	}

	
	protected static string GetTaskId(XDocument doc)
	{
		var id = string.Empty;
		var task = doc.Root.Element("task");
		if (task != null)
		{
			id = task.Attribute("id").Value;
		}
		return id;
	}

	
	protected static string GetStatus(XDocument doc)
	{
		var status = string.Empty;
		var task = doc.Root.Element("task");
		if (task != null)
		{
			status = task.Attribute("status").Value;
		}
		return status;
	}

	
	protected static string GetResultUrl(XDocument doc)
	{
		var resultUrl = string.Empty;
		var task = doc.Root.Element("task");
		if (task != null)
		{
			resultUrl = task.Attribute("resultUrl") != null ? task.Attribute("resultUrl").Value : string.Empty;
		}
		return resultUrl;
	}

	
	protected static string GetExtension(string exportFormat)
	{
		var extension = string.Empty;
		switch (exportFormat.ToLower())
		{
			case "txt":
				extension = "txt";
				break;
			case "rtf":
				extension = "rtf";
				break;
			case "docx":
				extension = "docx";
				break;
			case "xlsx":
				extension = "xlsx";
				break;
			case "pptx":
				extension = "pptx";
				break;
			case "pdfsearchable":
			case "pdftextandimages":
				extension = "pdf";
				break;
			case "xml":
				extension = "xml";
				break;
		}
		return extension;
	}

	
	private static int copyStream(Stream input, Stream output)
	{
		var buffer = new byte[8 * 1024];
		var streamLength = 0;
		int len;
		while ((len = input.Read(buffer, 0, buffer.Length)) > 0)
		{
			output.Write(buffer, 0, len);
			streamLength += len;
		}
		return streamLength;
	}

    protected void Page_Load(object sender, EventArgs e)
    {
        

        ApplicationId = "myApplicationId";
        Password = "myApplicationPassword";
        
        FilePath = "FileToRecognize.png";

        GetResult(ApplicationId, Password, FilePath, "English,German", "txt");
    }

	private IWebProxy _proxy;
	private ICredentials _credentials;
	
namespace ConsoleTest
{
    class Program
    {
        private static void displayHelp()
        {
            Console.WriteLine(
@"Usage:
ConsoleTest.exe [common options] <source_dir|file> <target>
  Perform full-text recognition of document

ConsoleTest.exe --asDocument [common options] <source_dir|file> <target_dir>
  Recognize file or directory treating each subdirectory as a single document

ConsoleTest.exe --asTextField [common options] <source_dir|file> <target_dir>
  Perform recognition via processTextField call

ConsoleTest.exe --asFields <source_file> <settings.xml> <target_dir>
  Perform recognition via processFields call. Processing settings should be specified in xml file.

ConsoleTest.exe --asMRZ <source_file> <target_dir>
  Recognize and parse Machine-Readable Zone (MRZ) of Passport, ID card, Visa or other official document          


Common options description:
--lang=<languages>: Recognize with specified language. Examples: --lang=English --lang=English,German,French
--profile=<profile>: Use specific profile: documentConversion, documentArchiving or textExtraction
--out=<output format>: Create output in specified format: txt, rtf, docx, xlsx, pptx, pdfSearchable, pdfTextAndImages, xml
--options=<string>: Pass additional arguments to RESTful calls
");    
        }

        static void Main(string[] args)
        {
            try
            {

                Test tester = new Test();

                ProcessingModeEnum processingMode = ProcessingModeEnum.SinglePage;

                string outFormat = null;
                string profile = null;
                string language = "english";
                string customOptions = "";

                var p = new OptionSet() {
                { "asDocument", v => processingMode = ProcessingModeEnum.MultiPage },
                { "asTextField", v => processingMode = ProcessingModeEnum.ProcessTextField},
                { "asFields", v => processingMode = ProcessingModeEnum.ProcessFields},
                { "asMRZ", var => processingMode = ProcessingModeEnum.ProcessMrz},
                { "captureData", v => processingMode = ProcessingModeEnum.CaptureData},
                { "out=", (string v) => outFormat = v },
                { "profile=", (string v) => profile = v },
                { "lang=", (string v) => language = v },
                { "options=", (string v) => customOptions = v }
            };

            List<string> additionalArgs = null;
            try
                {
                    additionalArgs = p.Parse(args);
                }
                catch (OptionException)
                {
                    Console.WriteLine("Invalid arguments.");
                    displayHelp();
                    return;
                }

            string sourcePath = null;
            string xmlPath = null;
            string targetPath = Directory.GetCurrentDirectory();
            string templateName = null;

            switch (processingMode)
            {
                case ProcessingModeEnum.SinglePage:
                    case ProcessingModeEnum.MultiPage:
                    case ProcessingModeEnum.ProcessTextField:
                    case ProcessingModeEnum.ProcessMrz:
                        if (additionalArgs.Count != 2)
                        {
                            displayHelp();
                            return;
                        }

                        sourcePath = additionalArgs[0];
                        targetPath = additionalArgs[1];
                        break;

                    case ProcessingModeEnum.ProcessFields:
                        if (additionalArgs.Count != 3)
                        {
                            displayHelp();
                            return;
                        }

                        sourcePath = additionalArgs[0];
                        xmlPath = additionalArgs[1];
                        targetPath = additionalArgs[2];
                        break;

                    case ProcessingModeEnum.CaptureData:
                        if (additionalArgs.Count != 3)
                        {
                            displayHelp();
                            return;
                        }

                        sourcePath = additionalArgs[0];
                        templateName = additionalArgs[1];
                        targetPath = additionalArgs[2];
                        break;
                }

                if (!Directory.Exists(targetPath))
                {
                    Directory.CreateDirectory(targetPath);
                }

                if (String.IsNullOrEmpty(outFormat))
                {
                    if (processingMode == ProcessingModeEnum.ProcessFields ||
                        processingMode == ProcessingModeEnum.ProcessTextField ||
                        processingMode == ProcessingModeEnum.ProcessMrz ||
                        processingMode == ProcessingModeEnum.CaptureData)
                        outFormat = "xml";
                    else
                        outFormat = "txt";
                }

                if (outFormat != "xml" &&
                    (processingMode == ProcessingModeEnum.ProcessFields ||
                    processingMode == ProcessingModeEnum.ProcessTextField) ||
                    processingMode == ProcessingModeEnum.CaptureData)
                {
                    Console.WriteLine("Only xml is supported as output format for field-level recognition.");
                    outFormat = "xml";
                }

                if (processingMode == ProcessingModeEnum.SinglePage || processingMode == ProcessingModeEnum.MultiPage)
                {
                    ProcessingSettings settings = buildSettings(language, outFormat, profile);
                    settings.CustomOptions = customOptions;
                    tester.ProcessPath(sourcePath, targetPath, settings, processingMode);
                }
                else if (processingMode == ProcessingModeEnum.ProcessTextField)
                {
                    TextFieldProcessingSettings settings = buildTextFieldSettings(language, customOptions);
                    tester.ProcessPath(sourcePath, targetPath, settings, processingMode);
                }
                else if (processingMode == ProcessingModeEnum.ProcessFields)
                {
                    string outputFilePath = Path.Combine(targetPath, Path.GetFileName(sourcePath) + ".xml");
                    tester.ProcessFields(sourcePath, xmlPath, outputFilePath);
                }
                else if (processingMode == ProcessingModeEnum.ProcessMrz)
                {
                    tester.ProcessPath(sourcePath, targetPath, null, processingMode);
                }
                else if (processingMode == ProcessingModeEnum.CaptureData)
                {
                    string outputFilePath = Path.Combine(targetPath, Path.GetFileName(sourcePath) + ".xml");
                    tester.CaptureData(sourcePath, templateName, outputFilePath);
                }


            }
            catch (Exception e)
            {
                Console.WriteLine("Error: ");
                Console.WriteLine(e.Message);
            }
        }

        private static ProcessingSettings buildSettings(string language,
            string outputFormat, string profile)
        {
            ProcessingSettings settings = new ProcessingSettings();
            settings.SetLanguage( language );
            switch (outputFormat.ToLower())
            {
                case "txt": settings.SetOutputFormat(OutputFormat.txt); break;
                case "rtf": settings.SetOutputFormat( OutputFormat.rtf); break;
                case "docx": settings.SetOutputFormat( OutputFormat.docx); break;
                case "xlsx": settings.SetOutputFormat( OutputFormat.xlsx); break;
                case "pptx": settings.SetOutputFormat( OutputFormat.pptx); break;
                case "pdfsearchable": settings.SetOutputFormat( OutputFormat.pdfSearchable); break;
                case "pdftextandimages": settings.SetOutputFormat( OutputFormat.pdfTextAndImages); break;
                case "xml": settings.SetOutputFormat( OutputFormat.xml); break;
                default:
                    throw new ArgumentException("Invalid output format");
            }
            if (profile != null)
            {
                switch (profile.ToLower())
                {
                    case "documentconversion":
                        settings.Profile = Profile.documentConversion;
                        break;
                    case "documentarchiving":
                        settings.Profile = Profile.documentArchiving;
                        break;
                    case "textextraction":
                        settings.Profile = Profile.textExtraction;
                        break;
                    default:
                        throw new ArgumentException("Invalid profile");
                }
            }

            return settings;
        }

        private static TextFieldProcessingSettings buildTextFieldSettings(string language, string customOptions)
        {
            TextFieldProcessingSettings settings = new TextFieldProcessingSettings();
            settings.Language = language;
            settings.CustomOptions = customOptions;
            return settings;
        }
    }

}
