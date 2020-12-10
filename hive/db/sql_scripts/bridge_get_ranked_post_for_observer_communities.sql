DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_created_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_created_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  __account_id = find_account_id( _observer, True );
  RETURN QUERY
    with post_ids as (select posts.id
                      from (select community_id
                            from hive_subscriptions
                            where account_id = __account_id) communities
                      cross join lateral (select hive_posts.id
                                          from hive_posts
                                          join hive_accounts on (hive_posts.author_id = hive_accounts.id)
                                          where hive_posts.community_id = communities.community_id
                                            and hive_posts.depth = 0
                                            and hive_posts.counter_deleted = 0
                                            and (__post_id = 0 OR hive_posts.id < __post_id)
                                            and hive_accounts.reputation > '-464800000000'::bigint
                                            and (not exists (select 1 from muted_accounts_by_id_view where observer_id = __account_id and muted_id = hive_posts.author_id))
                                          order by id desc
                                          limit _limit) posts
                      order by id desc
                      limit _limit)
      SELECT
          hp.id,
          hp.author,
          hp.parent_author,
          hp.author_rep,
          hp.root_title,
          hp.beneficiaries,
          hp.max_accepted_payout,
          hp.percent_hbd,
          hp.url,
          hp.permlink,
          hp.parent_permlink_or_category,
          hp.title,
          hp.body,
          hp.category,
          hp.depth,
          hp.promoted,
          hp.payout,
          hp.pending_payout,
          hp.payout_at,
          hp.is_paidout,
          hp.children,
          hp.votes,
          hp.created_at,
          hp.updated_at,
          hp.rshares,
          hp.abs_rshares,
          hp.json,
          hp.is_hidden,
          hp.is_grayed,
          hp.total_votes,
          hp.sc_trend,
          hp.role_title,
          hp.community_title,
          hp.role_id,
          hp.is_pinned,
          hp.curator_payout_value,
          hp.is_muted,
          blacklisted_by_observer_view.source
      from post_ids
      join hive_posts_view hp using (id)
      LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp.author_id)
      order by id desc;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_hot_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_hot_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __hot_limit FLOAT;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  IF __post_id <> 0 THEN
      SELECT hp.sc_hot INTO __hot_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      blacklisted_by_observer_view.source
  FROM
      hive_posts_view hp
      JOIN hive_subscriptions hs ON hp.community_id = hs.community_id
      LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp.author_id)
  WHERE hs.account_id = __account_id AND NOT hp.is_paidout AND hp.depth = 0
      AND ( __post_id = 0 OR hp.sc_hot < __hot_limit OR ( hp.sc_hot = __hot_limit AND hp.id < __post_id ) )
      AND (NOT EXISTS (SELECT 1 FROM muted_accounts_by_id_view WHERE observer_id = __account_id AND muted_id = hp.author_id))
  ORDER BY hp.sc_hot DESC, hp.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_payout_comments_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_payout_comments_for_observer_communities( in _observer VARCHAR,  in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __payout_limit hive_posts.payout%TYPE;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  IF __post_id <> 0 THEN
      SELECT ( hp.payout + hp.pending_payout ) INTO __payout_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      payout.blacklist_source
  FROM
  (
      SELECT
          hp1.id,
          ( hp1.payout + hp1.pending_payout ) as all_payout,
          blacklisted_by_observer_view.source as blacklist_source
      FROM
          hive_posts hp1
          JOIN hive_subscriptions hs ON hp1.community_id = hs.community_id
          LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp1.author_id)
      WHERE hs.account_id = __account_id AND hp1.counter_deleted = 0 AND NOT hp1.is_paidout AND hp1.depth > 0
          AND ( __post_id = 0 OR ( hp1.payout + hp1.pending_payout ) < __payout_limit OR ( ( hp1.payout + hp1.pending_payout ) = __payout_limit AND hp1.id < __post_id ) )
          AND (NOT EXISTS (SELECT 1 FROM muted_accounts_by_id_view WHERE observer_id = __account_id AND muted_id = hp1.author_id))
      ORDER BY ( hp1.payout + hp1.pending_payout ) DESC, hp1.id DESC
      LIMIT _limit
  ) as payout
  JOIN hive_posts_view hp ON hp.id = payout.id
  ORDER BY payout.all_payout DESC, payout.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_payout_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_payout_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __payout_limit hive_posts.payout%TYPE;
  __head_block_time TIMESTAMP;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  IF __post_id <> 0 THEN
      SELECT ( hp.payout + hp.pending_payout ) INTO __payout_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  __head_block_time = head_block_time();
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      blacklisted_by_observer_view.source
  FROM
      hive_posts_view hp
      JOIN hive_subscriptions hs ON hp.community_id = hs.community_id
      LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp.author_id)
  WHERE hs.account_id = __account_id AND NOT hp.is_paidout AND hp.payout_at BETWEEN __head_block_time + interval '12 hours' AND __head_block_time + interval '36 hours'
      AND ( __post_id = 0 OR ( hp.payout + hp.pending_payout ) < __payout_limit OR ( ( hp.payout + hp.pending_payout ) = __payout_limit AND hp.id < __post_id ) )
      AND (NOT EXISTS (SELECT 1 FROM muted_accounts_by_id_view WHERE observer_id = __account_id AND muted_id = hp.author_id))
  ORDER BY ( hp.payout + hp.pending_payout ) DESC, hp.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_promoted_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_promoted_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __promoted_limit hive_posts.promoted%TYPE;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  IF __post_id <> 0 THEN
      SELECT hp.promoted INTO __promoted_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      blacklisted_by_observer_view.source
  FROM
      hive_posts_view hp
      JOIN hive_subscriptions hs ON hp.community_id = hs.community_id
      LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp.author_id)
  WHERE hs.account_id = __account_id AND NOT hp.is_paidout AND hp.promoted > 0
      AND ( __post_id = 0 OR hp.promoted < __promoted_limit OR ( hp.promoted = __promoted_limit AND hp.id < __post_id ) )
      AND (NOT EXISTS (SELECT 1 FROM muted_accounts_by_id_view WHERE observer_id = __account_id AND muted_id = hp.author_id))
  ORDER BY hp.promoted DESC, hp.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_trends_for_observer_communities;
CREATE OR REPLACE FUNCTION bridge_get_ranked_post_by_trends_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __account_id INT;
  __trending_limit FLOAT := 0;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  __account_id = find_account_id( _observer, True );
  IF __post_id <> 0 THEN
      SELECT hp.sc_trend INTO __trending_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      trending.source
  FROM
  (
      SELECT
          hp1.id,
          hp1.sc_trend,
          blacklisted_by_observer_view.source as source
      FROM
          hive_posts hp1
          JOIN hive_subscriptions hs ON hp1.community_id = hs.community_id
          LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp1.author_id)
      WHERE
          hs.account_id = __account_id AND hp1.counter_deleted = 0 AND NOT hp1.is_paidout AND hp1.depth = 0
          AND ( __post_id = 0 OR hp1.sc_trend < __trending_limit OR ( hp1.sc_trend = __trending_limit AND hp1.id < __post_id ) )
          AND (NOT EXISTS (SELECT 1 FROM muted_accounts_by_id_view WHERE observer_id = __account_id AND muted_id = hp1.author_id))
      ORDER BY hp1.sc_trend DESC, hp1.id DESC
      LIMIT _limit
  ) trending
  JOIN hive_posts_view hp ON trending.id = hp.id
  ORDER BY trending.sc_trend DESC, trending.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;

DROP FUNCTION IF EXISTS bridge_get_ranked_post_by_muted_for_observer_communities;
CREATE FUNCTION bridge_get_ranked_post_by_muted_for_observer_communities( in _observer VARCHAR, in _author VARCHAR, in _permlink VARCHAR, in _limit SMALLINT )
RETURNS SETOF bridge_api_post
AS
$function$
DECLARE
  __post_id INT;
  __payout_limit hive_posts.payout%TYPE;
  __account_id INT;
BEGIN
  __post_id = find_comment_id( _author, _permlink, True );
  IF __post_id <> 0 THEN
      SELECT ( hp.payout + hp.pending_payout ) INTO __payout_limit FROM hive_posts hp WHERE hp.id = __post_id;
  END IF;
  __account_id = find_account_id( _observer, True );
  RETURN QUERY SELECT
      hp.id,
      hp.author,
      hp.parent_author,
      hp.author_rep,
      hp.root_title,
      hp.beneficiaries,
      hp.max_accepted_payout,
      hp.percent_hbd,
      hp.url,
      hp.permlink,
      hp.parent_permlink_or_category,
      hp.title,
      hp.body,
      hp.category,
      hp.depth,
      hp.promoted,
      hp.payout,
      hp.pending_payout,
      hp.payout_at,
      hp.is_paidout,
      hp.children,
      hp.votes,
      hp.created_at,
      hp.updated_at,
      hp.rshares,
      hp.abs_rshares,
      hp.json,
      hp.is_hidden,
      hp.is_grayed,
      hp.total_votes,
      hp.sc_trend,
      hp.role_title,
      hp.community_title,
      hp.role_id,
      hp.is_pinned,
      hp.curator_payout_value,
      hp.is_muted,
      blacklisted_by_observer_view.source
  FROM
      hive_posts_view hp
      JOIN hive_subscriptions hs ON hp.community_id = hs.community_id
      JOIN hive_accounts_view ha ON ha.id = hp.author_id
      LEFT OUTER JOIN blacklisted_by_observer_view ON (blacklisted_by_observer_view.observer_id = __account_id AND blacklisted_by_observer_view.blacklisted_id = hp.author_id)
  WHERE hs.account_id = __account_id AND NOT hp.is_paidout AND ha.is_grayed AND ( hp.payout + hp.pending_payout ) > 0
      AND ( __post_id = 0 OR ( hp.payout + hp.pending_payout ) < __payout_limit OR ( ( hp.payout + hp.pending_payout ) = __payout_limit AND hp.id < __post_id ) )
  ORDER BY ( hp.payout + hp.pending_payout ) DESC, hp.id DESC
  LIMIT _limit;
END
$function$
language plpgsql STABLE;
