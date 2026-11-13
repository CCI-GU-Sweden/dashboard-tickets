"""Install restricted ticket deletion helpers without replacing existing functions."""
from importlib.resources import files
import uuid

from django.core.management.base import BaseCommand, CommandError
from django.db import DatabaseError, connections, transaction


NAMES = ('dashboard_purge_archived_ticket', 'dashboard_remove_ticket_image')


def _functions(cursor, schema):
    cursor.execute("""SELECT p.proname, pg_get_function_identity_arguments(p.oid), pg_get_functiondef(p.oid),
            p.prosecdef, p.proconfig, pg_get_userbyid(p.proowner) = current_user,
            EXISTS (SELECT 1 FROM aclexplode(COALESCE(p.proacl, acldefault('f',p.proowner))) a
                    WHERE a.grantee = 0 AND a.privilege_type = 'EXECUTE')
        FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname=%s AND p.proname=ANY(%s) ORDER BY p.proname,pg_get_function_identity_arguments(p.oid)""", [schema, list(NAMES)])
    result = []
    for name, args, definition, security, config, owner, public in cursor.fetchall():
        definition = definition.replace(f'FUNCTION "{schema}".', 'FUNCTION ').replace(f'FUNCTION {schema}.', 'FUNCTION ')
        result.append((name, args, definition, security, config, owner, public))
    return result


class Command(BaseCommand):
    help = 'Check or explicitly create restricted ticket deletion helpers.'

    def add_arguments(self, parser):
        parser.add_argument('--database', default='default')
        parser.add_argument('--apply', action='store_true')

    def handle(self, *args, **options):
        alias = options['database']
        db = connections[alias]
        if db.vendor != 'postgresql':
            raise CommandError('Ticket helper setup requires PostgreSQL.')
        sql = files('dashboard_tickets').joinpath('schema', 'helpers.sql').read_text(encoding='utf-8')
        ref = 'dashboard_check_' + uuid.uuid4().hex
        quoted = db.ops.quote_name(ref)
        try:
            with transaction.atomic(using=alias):
                with db.cursor() as cursor:
                    cursor.execute("SELECT pg_advisory_xact_lock(hashtextextended('cci-dashboard-schema-setup', 0))")
                    for table, privileges in (('accounts_ticketarchive', ('SELECT',)), ('microscope_ticket', ('SELECT', 'UPDATE', 'DELETE')), ('microscope_ticket_event', ('DELETE',)), ('microscope_ticket_image', ('DELETE',))):
                        qualified = f'public.{table}'
                        cursor.execute('SELECT to_regclass(%s)', [qualified])
                        if not cursor.fetchone()[0]:
                            raise CommandError(f'Required table {qualified} is missing.')
                        for privilege in privileges:
                            cursor.execute('SELECT has_table_privilege(current_user, %s, %s)', [qualified, privilege])
                            if not cursor.fetchone()[0]:
                                raise CommandError(f'Helper owner needs {privilege} on {qualified}.')
                    cursor.execute(f'CREATE SCHEMA {quoted}')
                    reference_sql = sql.replace('FUNCTION public.', f'FUNCTION {quoted}.')
                    cursor.execute(reference_sql)
                    expected = _functions(cursor, ref)
                    actual = _functions(cursor, 'public')
                    if actual:
                        if actual != expected:
                            raise CommandError('Existing ticket helpers collide or differ in definition, owner or PUBLIC access; review manually.')
                        outcome = 'Existing ticket helpers match; no changes made.'
                    elif options['apply']:
                        cursor.execute(sql)
                        outcome = 'Created restricted ticket helpers; runtime EXECUTE grants are still required.'
                    else:
                        outcome = 'No helper collisions found; rerun with --apply to create them.'
                    cursor.execute(f'DROP SCHEMA {quoted} CASCADE')
        except DatabaseError as exc:
            raise CommandError('Ticket helper setup failed; no changes were committed. Check permissions and collisions.') from exc
        self.stdout.write(self.style.SUCCESS(outcome))
