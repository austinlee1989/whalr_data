import boto3
import os
import gzip
import datetime
from dateutil import rrule
import csv
import json

s3 = boto3.resource('s3')
s3c = boto3.client('s3')

# key_name = str(raw_input("Enter the name of the customer you're pulling data for: \n"))
# start_date = str(raw_input("Enter the start date in the 'yyyymmdd' format: \n"))
# end_date = str(raw_input("Enter the end date in the 'yyyymmdd' format: \n"))

##customer names + API Key##
#chartio89732323  20160610 20160715
#panda43584783
#flow23947635
key_name = "chartio89732323"
start_date = "20160610"
end_date = "20160730"


def create_filenames(start_date, end_date, key_name):
    dates_str = []
    date_min = datetime.datetime.strptime(start_date, '%Y%m%d')
    date_max = datetime.datetime.strptime(end_date, '%Y%m%d')
    dates = list(rrule.rrule(rrule.DAILY,
                             dtstart=date_min,
                             until=date_max))
    for i in dates:
        for x in range(0, 24):
            if x < 10:
                date_string = key_name + "/v2/" + datetime.datetime.strftime(i, '%Y%m%d') + "0" + str(x) + "_0.gz"
            else:
                date_string = key_name + "/v2/" + datetime.datetime.strftime(i, '%Y%m%d') + str(x) + "_0.gz"
            dates_str.append(date_string)
    return dates_str


def data_pull(start_date, end_date, key_name):
    file_names = create_filenames(start_date, end_date, key_name)
    file_names_list = []
    counter_x = 0
    directory = "/Users/austin.lee/Desktop/working/" + key_name + "/v2/"
    if not os.path.exists(directory):
        os.makedirs(directory)
    for x in file_names:
        counter_x += 1
        try:
            s3c.download_file('events.whalr.com', x, "/Users/austin.lee/Desktop/working/" + str(x))
            if counter_x % 24 == 0:
                print "successfully downloaded {0}".format(x)
            file_names_list.append("/Users/austin.lee/Desktop/working/" + str(x))
        except:
            print "error, couldn't find {0}".format(x)
            continue
        finally:
            pass
    return file_names_list


def decompress_files(list_of_file_names):
    full_file = {}
    for i in list_of_file_names:
        with gzip.open(i, 'rb') as f:
            file_content = f.read()
            full_file[i] = file_content
    return full_file


#New JSON parser


def json_parser_general(list_of_dicts):
    list_of_jsons = []
    list_of_errors = []
    for j in list_of_dicts:
        json_string = j.replace("{'", '{"').replace("':'", '":"').replace("'}", '"}').replace(",'", ',"').replace("',", '",')
        try:
            json_string = json.loads(json_string)
            list_of_jsons.append(json_string)
        except:
            list_of_errors.append(json_string)
            print "failed to parse string: {0}".format(json_string)
            break
    return list_of_jsons


##designed for chartio ##

def identify_json_parser(list_of_identify_dicts):
    list_of_jsons = json_parser_general(list_of_identify_dicts)
    identify_object = []
    for i in range(0, len(list_of_jsons)):
        id_dict = dict()
        if 'traits' in list_of_jsons[i]:
            traits = list_of_jsons[i]['traits']
            for key, value in traits.items():
                if key != 'company':
                    id_dict[key] = value
            if 'company' in list_of_jsons[i]['traits']:
                company = list_of_jsons[i]['traits']['company']
                for key, value in company.items():
                    new_key = "company_" + key.encode('utf-8')
                    id_dict[new_key] = value
        if 'context' in list_of_jsons[i]:
            context = list_of_jsons[i]['context']
            for key, value in context.items():
                if key not in ['traits', 'page', 'library', 'campaign', 'user_agent']:
                    con_key = "context_" + key.encode('utf-8')
                    id_dict[con_key] = value
           ##save space- pulling out page info
            # page = list_of_jsons[i]['context']['page']
            # for key, value in page.items():
            #     page_key = "page_" + key.encode('utf-8')
            #     id_dict[page_key] = value
        id_dict['user_id'] = list_of_jsons[i]['user_id']
        id_dict['time_stamp'] = list_of_jsons[i]['time']
        identify_object.append(id_dict)
        if i % 10000 == 0:
            print "parsed {0} identify lines".format(i)
    return identify_object


def track_json_parser(list_of_track_dicts):
    list_of_jsons = json_parser_general(list_of_track_dicts)
    track_object = []
    for i in range(0, len(list_of_jsons)):
        track_dict = dict()
        if 'properties' in list_of_jsons[i]:
            properties = list_of_jsons[i]['properties']
            for key, value in properties.items():
                properties_key = "properties_" + key.encode('utf-8')
                track_dict[properties_key] = value
        track_dict['user_id'] = list_of_jsons[i]['user_id']
        track_dict['time_stamp'] = list_of_jsons[i]['time']
        track_dict['event'] = list_of_jsons[i]['event']
        track_dict['organization_id'] = list_of_jsons[i]['organization_id']
        track_object.append(track_dict)
        if i % 10000 == 0:
            print "parsed {0} identify lines".format(i)
    return track_object


#for Pandadocs
def identify_parser(identify):
    identify_outfile = []
    for i in range(0, len(identify)):
        identify_dict = {'user_id': '', 'anonymous_id': '', 'email': '', 'name': '', 'time': '', 'subscription_state': '', 'members_count': ''}
        # user_id
        user_id_start = identify[i].find("\"user_id\":\"") + len("\"user_id\":\"")
        user_id_end = identify[i].find("\",", user_id_start)
        user_id = identify[i][user_id_start: user_id_end]
        identify_dict['user_id'] = user_id

        # anon_id

        anon_id_start = identify[i].find("\"anonymous_id\":\"") + len("\"anonymous_id\":\"")
        anon_id_end = identify[i].find("\",", anon_id_start)
        anonymous_id = identify[i][anon_id_start: anon_id_end]
        identify_dict['anonymous_id'] = anonymous_id

        #traits

        traits_start = identify[i].find("\"traits\":{") + len("\"traits\":{")
        traits_end = identify[i].find("},", traits_start)
        traits = identify[i][traits_start: traits_end]

        #subtraits
        if traits.find("email\":") != -1:
            email_start = traits.find("email\":\"") + len("email\":\"")
            email_end = traits.find("\",", email_start)
            email = traits[email_start: email_end]
            identify_dict['email'] = email
        if traits.find("\"name\":\"") != -1:
            name_start = traits.find("\"name\":\"") + len("\"name\":\"")
            name_end = traits.find("\",", name_start)
            name = traits[name_start: name_end]
            identify_dict['name'] = name
        if traits.find("subscription_state\":\"") != -1:
            subscription_start = traits.find("subscription_state\":\"") + len("subscription_state\":\"")
            subscription_end = traits.find("\",", subscription_start)
            subscription = traits[subscription_start: subscription_end]
            identify_dict['subscription_state'] = subscription
        if traits.find("members_count") != -1:
            members_start = traits.find("members_count\":") + len("members_count\":")
            members_end = traits.find("}", members_start)
            members_count = traits[members_start: members_end]
            identify_dict['members_count'] = members_count

        #time
        time_start = identify[i].find("\"time\":") + len("\"time\":")
        time_end = identify[i].find("}", time_start)
        time = identify[i][time_start: time_end]
        identify_dict['time'] = time
        identify_outfile.append(identify_dict)
    return identify_outfile


def track_parser(track):
    track_outfile = []
    for i in range(0, len(track)):
        track_dict = {'user_id': '', 'event': '', 'time': '', 'anonymous_id': ''}
        # user_id
        if track[i].find("\"anonymous_id\":\"") == -1:
            user_id_start = track[i].find("\"user_id\":\"") + len("\"user_id\":\"")
            user_id_end = track[i].find("\",", user_id_start)
            user_id = track[i][user_id_start: user_id_end]
            anonymous_id = "null"
        else:
            user_id = "null"
            anon_id_start = track[i].find("\"anonymous_id\":\"") + len("\"anonymous_id\":\"")
            anon_id_end = track[i].find("\",", anon_id_start)
            anonymous_id = track[i][anon_id_start: anon_id_end]
        track_dict['anonymous_id'] = anonymous_id
        track_dict['user_id'] = user_id
        # time
        time_start = track[i].find("\"time\":") + len("\"time\":")
        time_end = track[i].find("}", time_start)
        time = track[i][time_start: time_end]
        track_dict['time'] = time
        # event
        event_start = track[i].find("\"event\":\"") + len("\"event\":\"")
        event_end = track[i].find("\",", event_start)
        event = track[i][event_start: event_end]
        track_dict['event'] = event
        track_outfile.append(track_dict)
    return track_outfile


def write_to_csv(list_of_dictionaries, output_name, key_name):
    csv_filename = str("/Users/austin.lee/Desktop/working/output/" + key_name + "/" + output_name + ".csv")
    csv_directory = str("/Users/austin.lee/Desktop/working/output/" + key_name)
    if not os.path.exists(csv_directory):
        os.makedirs(csv_directory)
    with open(csv_filename, 'wr') as csv_output:
        fieldnames = list_of_dictionaries[0].keys()
        writer = csv.DictWriter(csv_output, fieldnames=fieldnames)
        writer.writeheader()
        encode_error_counter = 0
        for i in range(0, len(list_of_dictionaries)):
            try:
                writer.writerow(list_of_dictionaries[i])
                if i % 1000 == 0:
                    print "wrote: {0} rows \n into: {1}".format(i, csv_filename)
            except UnicodeEncodeError:
                encode_error_counter += 1
                print "Unicode Error for: {0} \n Number errors = {1}".format(list_of_dictionaries[i], encode_error_counter)
                continue


def execute_etl(start_date, end_date, key_name):
    files = data_pull(start_date, end_date, key_name)
    full_file = decompress_files(files)
    full_file_keys = full_file.keys()
    messages_striped = []
    list_of_pages = []
    list_of_identify = []
    list_of_track = []
    list_of_exceptions = []
    list_of_alias = []
    for i in full_file_keys:
        full_file[i] = full_file[i].strip("\n").split("\t")
        for x in range(0, len(full_file[i])):
            if full_file[i][x][0] == "{":
                if full_file[i][x][-1] != "}":
                    messages_striped.append(full_file[i][x][:-20])
                else:
                    messages_striped.append(full_file[i][x])
                if len(messages_striped) % 100000 == 0:
                    print "len messages stripped: \n {0}".format(len(messages_striped))
    for j in range(0, len(messages_striped)):
        if messages_striped[j].find("\"type\":\"page\"") > 0:
            list_of_pages.append(messages_striped[j])
        elif messages_striped[j].find("\"type\":\"identify\"") > 0:
            list_of_identify.append(messages_striped[j])
        elif messages_striped[j].find("\"type\":\"track\"") > 0:
            list_of_track.append(messages_striped[j])
        elif messages_striped[j].find("\"type\":\"alias\"") > 0:
            list_of_alias.append(messages_striped[j])
        else:
            list_of_exceptions.append(messages_striped[j])
    identify_list_of_dicts = identify_json_parser(list_of_identify)
    track_list_of_dicts = track_json_parser(list_of_track)
    output_file_identify = str(key_name) + "_identify" + str(start_date)
    output_file_track = str(key_name) + "_track" + str(start_date)
    write_to_csv(identify_list_of_dicts, output_file_identify, key_name)
    write_to_csv(track_list_of_dicts, output_file_track, key_name)
    print "identify output will be length = {0}".format(len(identify_list_of_dicts))
    print "track output will be length = {0}".format(len(track_list_of_dicts))


def batch_executor(start_date, end_date, key_name):
    batch_start_dates = [start_date]
    for x in range(0, int(end_date) - int(start_date)):
        if x%10 == 0:
            batch_start_dates.append(str(int(start_date) + x))
    for el in range(0, len(batch_start_dates)):
        if el == len(batch_start_dates):
            execute_etl(batch_start_dates[el], end_date, key_name)
        else:
            end_date = batch_start_dates[el + 1]
            execute_etl(batch_start_dates[el], end_date, key_name)


batch_executor(start_date, end_date, key_name)









