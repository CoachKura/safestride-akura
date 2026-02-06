import 'package:akura_mobile/services/supabase_service.dart';
import 'package:akura_mobile/models/activity.dart';

class ActivityService {
  static Future<void> saveActivity(Activity activity) async {
    await SupabaseService.client
        .from('activities')
        .insert(activity.toJson());
  }

  static Future<List<Activity>> getActivities(String userId) async {
    final response = await SupabaseService.client
        .from('activities')
        .select()
        .eq('athlete_id', userId)
        .order('activity_date', ascending: false);

    return (response as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

  static Future<void> updateActivity(String id, Activity activity) async {
    await SupabaseService.client
        .from('activities')
        .update(activity.toJson())
        .eq('id', id);
  }

  static Future<void> deleteActivity(String id) async {
    await SupabaseService.client
        .from('activities')
        .delete()
        .eq('id', id);
  }
}
