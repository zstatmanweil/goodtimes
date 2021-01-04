from datetime import datetime


def get_time_diff_hrs(created: datetime) -> int:
    """
    Get the time difference between created timestamp and now.
    :param created:
    :return: time in hours
    """
    diff = datetime.utcnow() - created
    return round(diff.total_seconds() / 60 / 60)
