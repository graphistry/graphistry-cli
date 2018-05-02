import requests
import random
from prompt_toolkit.formatted_text import HTML


def hints():
    """
    Random helpful hints.
    """
    hints = [
        'If you press meta-! or esc-! at the following prompt, you can enter system commands.',
        'Take the elevator instead of the stairs.'
    ]
    return random.choice(hints)


def celebrity_name():
    """
    get a random name from this list
    """
    celebs = ['Albert Einstein', 'Benjamin Franklin', 'Marilyn Monroe',
              'Thomas Jefferson', 'Henry Rollins', 'Eli Whitney',
              'Grace Hopper', 'Alexander Hamilton', 'Cleopatra',
              'George Washington Carver', 'Marie Curie', 'Sally Ride',
              'David Lynch']
    return random.choice(celebs)


def whatthecommit():
    """
    Get random commit message from whatthecommit.com dictionary
    """
    commits = ['Crap. Tonight is raid night and I am already late.', 'Do things better, faster, stronger',
               'fix bug, for realz', 'Yep, Edy was right on this one.', '[Insert your commit message here. Be sure to make it descriptive.]',
               'I am Spartacus', 'Reticulating splines...', '[no message]', 'Add Sandbox', 'Added another dependency',
               'It\'s getting hard to keep up with the crap I\'ve trashed', "I don't know what the hell I was thinking.",
               "add actual words", "remove certain things and added stuff", "stopped caring 14 commits ago",
               "woa!! this one was really HARD!", "a few bits tried to escape, but we caught them", "ffs", "the magic is real",
               "I'm hungry", "just checking if git is working properly...", "totally more readable", "arrrggghhhhh fixed!"]
    return random.choice(commits)


def revisionist_commit_history():
    """
    Historical figures make shitty commits
    """
    return '"{}" --{}'.format(whatthecommit(), celebrity_name())


def revisionist_commit_history_html():
    """
    Historical figures make shitty commits
    """
    return HTML('"{}" <b>--{}</b>'.format(whatthecommit(), celebrity_name()))