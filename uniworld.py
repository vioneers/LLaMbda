kind = { 'Oxford':'university', 'Harvard':'university', 'MIT':'university',
         'Stanford':'university', 'Columbia':'university', 'ETH':'university',
         'EPFL':'university',
         'Maria':'person', 'Teodora':'person', 'Villads':'person',
         'Eva':'person', 'Ioana':'person', 'Luxin':'person',
         'Hugo':'person', 'Nadia':'person', 'Tom':'person', 'Sarah':'person',
         'Functional Programming':'course', 'Statistics':'course', 'Compilers':'course',
         'Analysis':'course', 'Algebra':'course'}

entities = list(kind)

universities = { x for x in kind if kind[x] == 'university' }
people       = { x for x in kind if kind[x] == 'person'}
students     = { 'Maria', 'Teodora', 'Villads', 'Eva', 'Ioana', 'Luxin', 'Hugo', 'Nadia' }
courses      = { x for x in kind if kind[x] == 'course' }

easy        = { 'Statistics', 'Algebra' }
challenging = { 'Compilers', 'Analysis', 'Functional Programming' }

smart       = { 'Maria', 'Teodora', 'Villads', 'Eva', 'Ioana', 'Luxin' , 'Sarah'}
first_year  = { 'Nadia', 'Villads' }
second_year = { 'Hugo' , 'Eva', 'Luxin'}
final_year  = { 'Maria', 'Teodora', 'Ioana'}
tired       = { 'Hugo', 'Nadia', 'Teodora' , 'Tom'}

selective   = { 'Oxford', 'Harvard', 'MIT', 'Stanford', 'ETH' }
expensive   = { 'Harvard', 'Stanford', 'Columbia' }

graduates      = { 'Tom' }
works          = { 'Teodora', 'Ioana', 'Hugo' }

attends = { ('Maria','ETH'), ('Teodora','ETH'), ('Villads','MIT'), ('Eva','Oxford'),
            ('Ioana','Stanford'), ('Luxin','Harvard'), ('Hugo','Columbia'), ('Nadia','EPFL') }

studies = { ('Maria','Functional Programming'), ('Maria','Algebra'),
            ('Teodora','Compilers'), ('Teodora','Functional Programming'),
            ('Villads','Analysis'), ('Eva','Statistics'), ('Ioana','Algebra'),
            ('Luxin','Functional Programming'), ('Hugo','Analysis'), ('Nadia','Compilers') }
passed  = { ('Maria','Functional Programming'), ('Teodora','Functional Programming'), ('Teodora','Compilers'), ('Villads','Analysis'),
            ('Eva','Statistics'), ('Ioana','Algebra'), ('Luxin','Functional Programming') }
failed  = { ('Hugo','Analysis'), ('Nadia','Compilers') }
aced    = { ('Maria','Functional Programming'), ('Teodora','Functional Programming') }

def graduate(person: str) -> str:
    if person in students:
        if person in final_year:
            current_uni = 'unknown university'
            for (student, uni) in attends:
                if student == person: 
                    current_uni = uni
                    break
            students.remove(person)
            final_year.remove(person)
            graduates.add(person)
            return f'Graduated {person} from {current_uni}'
        else:
            return f'{person} not in final year of studies'
    else:
        return f'{person} is not a student'

def enroll(person: str) -> str:
    if person not in people:
        return f'{person} is not a known person'
    if person in students:
        return f'{person} is already enrolled in university'
    students.add(person)
    first_year.add(person)
    return f'Enrolled {person}'

def advance(person: str) -> str:
    if person not in students:
        return f'{person} is not a student'
    current_uni = 'unknown university'
    for (student, uni) in attends:
        if student == person: 
            current_uni = uni
            break
    if person in first_year:
        first_year.remove(person)
        second_year.add(person)
        return f'Advanced {person} to second year at {current_uni}'
    if person in second_year:
        second_year.remove(person)
        final_year.add(person)
        return f'Advanced {person} to third (final) year at {current_uni}'
    if person in final_year:
        final_year.remove(person)
        students.remove(person)
        graduates.add(person)
        return f'Graduated {person} from {current_uni}'
    return f'Cannot advance {person}: current year is unknown'