import json
import copy
import argparse


def main():

    parser = argparse.ArgumentParser(description='Modify a final JSON file produced by the Next strain augur workflow'
                                                 'prior to public deployment')
    parser.add_argument('--input_json', '-i', type=str, help='Input Next strain JSON to modify',
                        required=True)
    parser.add_argument('--output_json', '-o', type=str, help='Output Next strain JSON',
                        required=True)

    args = parser.parse_args()
    ncov_json = json.load(open(args.input_json, "r"))

    # rename the titles in the colorings
    ncov_json["meta"]['colorings'][1]['title'] = "Date"
    ncov_json["meta"]['colorings'][0]['title'] = "Nextstrain Clade"

    # make a deep copy to re-order coloring keys
    copy_of_json = copy.deepcopy(ncov_json)

    # establish the order of color keys
    old_order_colorings = ["clade_membership", "num_date", "gt", "Country", "Health.Region", "GISAID.Clade",
                           "Pango.Lineage", "VOC.Lineage", "Age.Group", "Sex"]
    new_order_colorings = ["num_date", "Country", "Health.Region", "clade_membership", "GISAID.Clade", "Pango.Lineage",
                           "VOC.Lineage", "Age.Group", "Sex", "gt"]

    # create the new order in the json copy
    for i in new_order_colorings:
        copy_of_json["meta"]['colorings'][new_order_colorings.index(i)] =\
            ncov_json["meta"]['colorings'][old_order_colorings.index(i)]

    out_json = open(args.output_json, "w")
    json.dump(copy_of_json, out_json)


if __name__ == '__main__':
    main()
