kind = { 'Oxford':'university', 'Harvard':'university', 'MIT':'university',
         'Stanford':'university', 'Columbia':'university', 'ETH':'university',
         'EPFL':'university',
         'Maria':'student', 'Teodora':'student', 'Villads':'student',
         'Eva':'student', 'Ioana':'student', 'Luxin':'student',
         'Hugo':'student', 'Nadia':'student',
         'Functional Programming':'course', 'Statistics':'course', 'Compilers':'course',
         'Analysis':'course', 'Algebra':'course'}

entities = list(kind)

universities = { x for x in kind if kind[x] == 'university' }
students     = { x for x in kind if kind[x] == 'student' }
courses      = { x for x in kind if kind[x] == 'course' }

easy        = { 'Statistics', 'Algebra' }
challenging = { 'Compilers', 'Analysis', 'Functional Programming' }

smart       = { 'Maria', 'Teodora', 'Villads', 'Eva', 'Ioana', 'Luxin' }
tired       = { 'Hugo', 'Nadia', 'Teodora' }

selective   = { 'Oxford', 'Harvard', 'MIT', 'Stanford', 'ETH' }
expensive   = { 'Harvard', 'Stanford', 'Columbia' }

graduates      = { 'Maria', 'Villads', 'Eva' }
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

