kind = { 'Brian':'badger', 'Conor':'cat', 'Dara':'dog', 'Fiona':'dog',
         'Ronan':'mouse', 'Seamus':'cat', 'Tara':'mouse' }
animals = list(kind)

swim   = { 'Brian', 'Fiona' }
sleep  = { 'Seamus' }

chase  = { ('Dara','Fiona'), ('Fiona','Conor'), ('Conor','Tara'), ('Seamus','Ronan') }
fear   = { ('Tara','Conor'), ('Tara','Seamus'), ('Ronan','Brian'),
           ('Conor','Fiona'), ('Seamus','Dara'), ('Fiona','Dara'),
           ('Brian','Fiona') }

hungry = { 'Conor', 'Dara', 'Ronan' }
grey   = { 'Seamus', 'Tara' }

def feed(animal: str) -> str:
    if animal in animals:
        if animal in hungry:
            hungry.remove(animal)
            return f'Fed {animal}'
        else:
            return f'{animal} not hungry'
    else:
        return f'Animal {animal} is unknown'

def wake(animal: str) -> str:
    if animal in animals:
        if animal in sleep:
            sleep.remove(animal)
            return f'Woke up {animal}'
        else:
            return f'{animal} already awake'
    else:
        return f'Animal {animal} is unknown'