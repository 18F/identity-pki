def section(d):
    """
    Helper function to generate OSCAL section structure.
    """
    id = d["id"]
    title = d["title"]
    prose = d["prose"]
    return {
        "id": f"s{id}",
        "class": "section",
        "title": title,
        "props": [{"name": "label", "value": id,}],
        "parts": [{"id": f"s{id}_smt", "name": "objective", "prose": prose}],
        "controls": [],
    }
