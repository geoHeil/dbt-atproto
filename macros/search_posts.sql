{% macro search_posts(handle, text='%', max=25) %}
  {{ adapter.dispatch('search_posts', 'dbt_atproto')(handle, text, max) }}
{% endmacro %}

{% macro duckdb__search_posts(handle, text='%', max=25) -%}
(
  WITH raw_data AS (
      SELECT * FROM read_json_auto(
          'https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor={{ handle }}&limit={{ max }}'
      )
  ),
  unnested_feed AS (
      SELECT unnest(feed) AS post_data FROM raw_data
  )
  SELECT 
      -- Post basics
      post_data.post.author.handle AS author_handle,
      post_data.post.author.displayName AS display_name,
      
      -- Post content
      post_data.post.record.text AS post_text,
      post_data.post.record.createdAt AS created_at,
      post_data.post.uri AS post_uri,
      
      -- Engagement metrics
      post_data.post.replyCount AS replies,
      post_data.post.repostCount AS reposts,
      post_data.post.likeCount AS likes,
      post_data.post.quoteCount AS quotes
  FROM unnested_feed
  WHERE 
      post_data.post.author.handle LIKE '{{ handle }}' 
      AND post_data.post.record.text LIKE '%{{ text }}%'
  ORDER BY created_at DESC
)
{%- endmacro %}
