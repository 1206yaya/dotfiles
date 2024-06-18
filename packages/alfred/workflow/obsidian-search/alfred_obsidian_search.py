import sys
import urllib.parse

def generate_obsidian_url(query):
    encoded_query = urllib.parse.quote(query)
    url = f"obsidian://search?vault=fluttrer_pub_docs&query=%5B%22tags%22%3A{encoded_query}%20OR%20flutter%5D%20"
    return url

if __name__ == "__main__":
    if len(sys.argv) > 1:
        query = ' '.join(sys.argv[1:])
        url = generate_obsidian_url(query)
        print(url)
    else:
        print("No query provided.")
