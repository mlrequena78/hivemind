"""Cursor-based pagination queries, mostly supporting condenser_api."""

from hive.server.common.helpers import last_month

from hive.server.condenser_api.objects import _condenser_post_object
from hive.server.database_api.methods import find_votes_impl, VotesPresentation

# pylint: disable=too-many-lines

async def get_post_id(db, author, permlink):
    """Given an author/permlink, retrieve the id from db."""
    sql = """
        SELECT
            hp.id
        FROM hive_posts hp
        INNER JOIN hive_accounts ha_a ON ha_a.id = hp.author_id
        INNER JOIN hive_permlink_data hpd_p ON hpd_p.id = hp.permlink_id
        WHERE ha_a.name = :author AND hpd_p.permlink = :permlink
            AND counter_deleted = 0 LIMIT 1""" # ABW: replace with find_comment_id(:author,:permlink,True)?
    return await db.query_one(sql, author=author, permlink=permlink)

async def get_followers(db, account: str, start: str, follow_type: str, limit: int):
    """Get a list of accounts following by a given account."""
    state = 2 if follow_type == 'ignore' else 1
    sql = " SELECT * FROM condenser_get_names_by_followers( '{}', '{}', {}::SMALLINT, {}::SMALLINT ) ".format( account, start, state, limit )

    return await db.query_col(sql)

async def get_following(db, account: str, start: str, follow_type: str, limit: int):
    """Get a list of accounts followed by a given account."""
    state = 2 if follow_type == 'ignore' else 1
    sql = " SELECT * FROM condenser_get_names_by_following( '{}', '{}', {}::SMALLINT, {}::SMALLINT ) ".format( account, start, state, limit )

    return await db.query_col(sql)

async def get_follow_counts(db, account: str):
    """Return following/followers count for `account`."""
    sql = "SELECT * FROM condenser_get_follow_counts( '{}' )".format( account )
    return dict (await db.query_row(sql) )

async def get_reblogged_by(db, author: str, permlink: str):
    """Return all rebloggers of a post."""

    sql = "SELECT * FROM condenser_get_names_by_reblogged( '{}', '{}' )".format( author, permlink )
    names = await db.query_col(sql)

    if author in names:
        names.remove(author)
    return names

async def get_data(db, sql:str, truncate_body: int = 0):
    result = await db.query_all(sql); 

    posts = []
    for row in result:
        row = dict(row)
        post = _condenser_post_object(row, truncate_body=truncate_body)

        post['active_votes'] = await find_votes_impl(db, row['author'], row['permlink'], VotesPresentation.CondenserApi)
        posts.append(post)

    return posts

async def get_by_blog_without_reblog(db, account: str, start_permlink: str = '', limit: int = 20, truncate_body: int = 0):
  """Get a list of posts for an author's blog without reblogs."""
  sql = " SELECT * FROM condenser_get_by_blog_without_reblog( '{}', '{}', {} ) ".format( account, start_permlink, limit )
  return await get_data(db, sql, truncate_body )

async def get_by_account_comments(db, account: str, start_permlink: str = '', limit: int = 20, truncate_body: int = 0):
  """Get a list of posts representing comments by an author."""
  sql = " SELECT * FROM condenser_get_by_account_comments( '{}', '{}', {} ) ".format( account, start_permlink, limit )
  return await get_data(db, sql, truncate_body )

async def get_by_replies_to_account(db, start_author: str, start_permlink: str = '', limit: int = 20, truncate_body: int = 0):
  """Get a list of posts representing replies to an author."""
  sql = " SELECT * FROM condenser_get_by_replies_to_account( '{}', '{}', {} ) ".format( start_author, start_permlink, limit )
  return await get_data(db, sql, truncate_body )

async def get_by_blog(db, account: str = '', start_author: str = '', start_permlink: str = '', limit: int = 20):
  """Get a list of posts for an author's blog."""
  sql = " SELECT * FROM condenser_get_by_blog( '{}', '{}', '{}', {} ) ".format( account, start_author, start_permlink, limit )
  return await get_data(db, sql )
