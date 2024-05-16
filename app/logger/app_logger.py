import logging
import sys


def get_app_logger(module_name: str):
    logger = logging.getLogger(module_name)
    logger.setLevel(logging.INFO)

    stream_handler = logging.StreamHandler(sys.stdout)
    log_formatter = logging.Formatter(
        "%(asctime)s [%(processName)s: %(process)d] [%(threadName)s: %(thread)d] [%(levelname)s] %(name)s: %(message)s"
    )

    stream_handler.setFormatter(log_formatter)
    logger.addHandler(stream_handler)

    return logger
